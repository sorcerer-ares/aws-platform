# 1. CloudWatch Log Group for Observability
resource "aws_cloudwatch_log_group" "ecs_log_group" {
  name              = "/ecs/preview-platform"
  retention_in_days = 7 # FinOps: Keeps costs down by not storing logs forever
}

# 2. ECS Cluster
resource "aws_ecs_cluster" "app_cluster" {
  name = "preview-platform-cluster"
}

# 3. ECS Task Definition
resource "aws_ecs_task_definition" "app_task" {
  family                   = "preview-app-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256" # Cost-conscious: minimal compute for a FastAPI demo
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "preview-app"
      image     = "${aws_ecr_repository.app_repo.repository_url}:latest" 
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
          "awslogs-group"         = aws_cloudwatch_log_group.ecs_log_group.name
          "awslogs-region"        = "us-east-1"
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}

# 4. ECS Service
resource "aws_ecs_service" "app_service" {
  name            = "preview-app-service"
  cluster         = aws_ecs_cluster.app_cluster.id
  task_definition = aws_ecs_task_definition.app_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.public_subnet_a.id, aws_subnet.public_subnet_b.id]
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = true # Crucial: Allows Fargate to pull from ECR without a NAT Gateway
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app_tg.arn
    container_name   = "preview-app"
    container_port   = 8000
  }

  # Ensure the ALB listener exists before starting the service
  depends_on = [aws_lb_listener.http_listener]
}
