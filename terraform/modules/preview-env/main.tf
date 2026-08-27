variable "pr_number" { type = string }
variable "image_tag" { type = string }
variable "vpc_id" { type = string }
variable "public_subnets" { type = list(string) }
variable "ecs_security_group_id" { type = string }
variable "ecs_cluster_id" { type = string }
variable "alb_listener_arn" { type = string }
variable "ecr_repository_url" { type = string }
variable "execution_role_arn" { type = string }
variable "task_role_arn" { type = string }
variable "log_group_name" { type = string }

# 1. Isolated Target Group for this PR
resource "aws_lb_target_group" "pr_tg" {
  name        = "preview-tg-pr-${var.pr_number}"
  port        = 8000
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path                = "/health"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 10
    matcher             = "200"
  }
}

# 2. Dynamic ALB Listener Rule (Routes /pr-X/* to this PR's target group)
resource "aws_lb_listener_rule" "pr_rule" {
  listener_arn = var.alb_listener_arn
  priority     = var.pr_number

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

# 3. Dynamic ECS Task Definition
resource "aws_ecs_task_definition" "pr_task" {
  family                   = "preview-task-pr-${var.pr_number}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = var.execution_role_arn
  task_role_arn            = var.task_role_arn

  container_definitions = jsonencode([
    {
      name      = "preview-app"
      image     = "${var.ecr_repository_url}:${var.image_tag}"
      essential = true
      portMappings = [
        {
          containerPort = 8000
          hostPort      = 8000
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = var.log_group_name
          "awslogs-region"        = "us-east-1"
          "awslogs-stream-prefix" = "pr-${var.pr_number}"
        }
      }
    }
  ])
}

# 4. Isolated ECS Service
resource "aws_ecs_service" "pr_service" {
  name            = "preview-service-pr-${var.pr_number}"
  cluster         = var.ecs_cluster_id
  task_definition = aws_ecs_task_definition.pr_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  network_configuration {
    subnets          = var.public_subnets
    security_groups  = [var.ecs_security_group_id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.pr_tg.arn
    container_name   = "preview-app"
    container_port   = 8000
  }

  depends_on = [aws_lb_listener_rule.pr_rule]
}
