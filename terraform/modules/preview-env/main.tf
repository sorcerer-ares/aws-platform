terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  backend "s3" {
    bucket = "iski-bucket-uski-bucket-thisismybucket" # Replace with your tfstate bucket name if different
    region = "us-east-1"
  }
}

provider "aws" {
  region = var.aws_region
}

# 1. Reference Base Shared Infrastructure
data "aws_vpc" "main" {
  filter {
    name   = "tag:Name"
    values = ["preview-platform-vpc"]
  }
}

data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }
}

data "aws_lb" "alb" {
  name = "preview-platform-alb"
}

data "aws_lb_listener" "http" {
  load_balancer_arn = data.aws_lb.alb.arn
  port              = 80
}

data "aws_ecs_cluster" "cluster" {
  cluster_name = "preview-platform-cluster"
}

data "aws_security_group" "ecs_sg" {
  name = "preview-platform-ecs-sg" # Ensure matches your base ECS security group name tag
}

data "aws_iam_role" "ecs_execution_role" {
  name = "preview-ecs-execution-role"
}

# 2. Ephemeral Target Group for this PR
resource "aws_lb_target_group" "pr_tg" {
  name        = "tg-pr-${var.pr_number}"
  port        = 8000
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.main.id
  target_type = "ip"

  health_check {
    path                = "/health"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Environment = "pr-${var.pr_number}"
  }
}

# 3. Path-Based Listener Rule: Route /pr-<number>/* to PR Target Group
resource "aws_lb_listener_rule" "pr_rule" {
  listener_arn = data.aws_lb_listener.http.arn
  priority     = tonumber(var.pr_number) + 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.pr_tg.arn
  }

  condition {
    path_pattern {
      values = ["/pr-${var.pr_number}*"]
    }
  }
}

# 4. PR-Specific Task Definition
resource "aws_ecs_task_definition" "pr_task" {
  family                   = "preview-task-pr-${var.pr_number}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = data.aws_iam_role.ecs_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "preview-app"
      image     = "357919579947.dkr.ecr.us-east-1.amazonaws.com/dev-platform:${var.image_tag}"
      essential = true
      portMappings = [
        {
          containerPort = 8000
          hostPort      = 8000
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/preview-platform"
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "pr-${var.pr_number}"
        }
      }
    }
  ])
}

# 5. PR ECS Service
resource "aws_ecs_service" "pr_service" {
  name            = "service-pr-${var.pr_number}"
  cluster         = data.aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.pr_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = data.aws_subnets.public.ids
    security_groups  = [data.aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.pr_tg.arn
    container_name   = "preview-app"
    container_port   = 8000
  }

  depends_on = [aws_lb_listener_rule.pr_rule]
}
