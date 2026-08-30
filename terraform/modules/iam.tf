# ==========================================
# 1. ECS TASK EXECUTION ROLE (Infrastructure)
# ==========================================
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "preview-ecs-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ==========================================
# 2. ECS TASK ROLE (Application Container)
# ==========================================
resource "aws_iam_role" "ecs_task_role" {
  name = "preview-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

# ==========================================
# 3. GITHUB OIDC IDENTITY PROVIDER
# ==========================================
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1c58a3a8518e8759bf075b76b750d4f2df264fcd"
  ]
}

# ==========================================
# 4. GITHUB ACTIONS RUNNER IAM ROLE
# ==========================================
resource "aws_iam_role" "github_actions_role" {
  name = "preview-github-actions-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Condition = {
          "StringEquals" = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          },
          "StringLike" = {
            "token.actions.githubusercontent.com:sub" = [
              "repo:sorcerer-ares/aws-platform:*",
              "repo:sorcerer-ares@*/aws-platform@*:*"
            ]
          }
        }
      }
    ]
  })
}

# ==========================================
# 5. GITHUB ACTIONS POLICIES
# ==========================================

# ECR Push/Pull Policy
resource "aws_iam_role_policy_attachment" "github_actions_ecr_policy" {
  role       = aws_iam_role.github_actions_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}

# S3 Terraform State Management Policy
resource "aws_iam_policy" "github_actions_s3_backend" {
  name        = "preview-github-actions-s3-backend"
  description = "Allows GitHub Actions runner to manage Terraform state in S3"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "TerraformStateBucketLevel"
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ]
        Resource = "arn:aws:s3:::iski-bucket-uski-bucket-thisismybucket"
      },
      {
        Sid    = "TerraformStateObjectLevel"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = "arn:aws:s3:::iski-bucket-uski-bucket-thisismybucket/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "github_actions_s3_attach" {
  role       = aws_iam_role.github_actions_role.name
  policy_arn = aws_iam_policy.github_actions_s3_backend.arn
}

# Infrastructure Provisioning Permissions (ECS, ELB, VPC Reads, CloudWatch)
resource "aws_iam_role_policy_attachment" "github_actions_poweruser" {
  role       = aws_iam_role.github_actions_role.name
  policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
}
# In terraform/modules/iam.tf, add this policy:
resource "aws_iam_policy" "github_actions_ecs_iam_pass" {
  name        = "preview-github-actions-ecs-iam-pass"
  description = "Allows GitHub Actions runner to get and pass ECS execution roles"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "iam:GetRole",
          "iam:PassRole"
        ]
        Resource = [
          "arn:aws:iam::357919579947:role/preview-ecs-execution-role",
          "arn:aws:iam::357919579947:role/preview-ecs-task-role"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "github_actions_ecs_iam_pass_attach" {
  role       = aws_iam_role.github_actions_role.name
  policy_arn = aws_iam_policy.github_actions_ecs_iam_pass.arn
}
