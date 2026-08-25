# 1. Application Load Balancer
resource "aws_lb" "preview_alb" {
  name               = "preview-platform-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [
    aws_subnet.public_subnet_a.id, 
    aws_subnet.public_subnet_b.id
  ]

  tags = {
    Name = "preview-alb"
  }
}

# 2. Target Group for ECS Fargate
resource "aws_lb_target_group" "app_tg" {
  name        = "preview-app-tg"
  port        = 8000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.myvpc.id
  target_type = "ip" # Crucial: Fargate requires target_type "ip"

  health_check {
    path                = "/health"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 10
    matcher             = "200"
  }
}

# 3. ALB Listener
resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.preview_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}
