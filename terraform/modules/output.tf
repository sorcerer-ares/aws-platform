
output "repository_url" {
  description = "The URL of the repository"
  value       = aws_ecr_repository.app_repo.repository_url
}
# 1. ECR Repository URL (Required for GitHub Actions to tag and push Docker images)
output "ecr_repository_url" {
  description = "The URL of the ECR repository"
  value       = aws_ecr_repository.app_repo.repository_url
}

# 2. ALB DNS Name (The public preview base URL)
output "alb_dns_name" {
  description = "Public DNS name of the Application Load Balancer"
  value       = aws_lb.preview_alb.dns_name
}

# 3. ALB Listener ARN (Required for dynamic PR routing rules in M4)
output "alb_listener_arn" {
  description = "ARN of the ALB HTTP listener"
  value       = aws_lb_listener.http_listener.arn
}

# 4. ECS Cluster Details
output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.app_cluster.name
}

output "ecs_cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = aws_ecs_cluster.app_cluster.arn
}

# 5. Networking Identifiers (Needed for deploying isolated preview services)
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.myvpc.id
}

output "public_subnet_ids" {
  description = "List of public subnet IDs for ECS tasks"
  value       = [aws_subnet.public_subnet_a.id, aws_subnet.public_subnet_b.id]
}

output "ecs_security_group_id" {
  description = "Security Group ID attached to ECS tasks"
  value       = aws_security_group.ecs_sg.id
}

# 6. IAM Roles
output "ecs_task_execution_role_arn" {
  description = "ARN of the ECS Task Execution Role"
  value       = aws_iam_role.ecs_task_execution_role.arn
}

output "github_actions_role_arn" {
  description = "ARN of the IAM role assumed by GitHub Actions via OIDC"
  value       = aws_iam_role.github_actions_role.arn
}
