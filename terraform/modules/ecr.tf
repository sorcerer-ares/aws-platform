# 1. ECR Repository
resource "aws_ecr_repository" "app_repo" {
  name                 = "dev-platform"  # Name of your ECR repository
  image_tag_mutability = "MUTABLE"       # Change to "IMMUTABLE" if you don't want tags overwritten

  image_scanning_configuration {
    scan_on_push = true                  # Automatically scan images for vulnerabilities on push
  }

  force_delete = true                    # Allows deletion of repository even if it contains images (useful for dev/test)
}

# 2. Lifecycle Policy (Cleans up untagged or old images to reduce storage costs)
resource "aws_ecr_lifecycle_policy" "app_repo_policy" {
  repository = aws_ecr_repository.app_repo.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Expire untagged images older than 7 days"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 7
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Keep last 15 tagged images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 15
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}
