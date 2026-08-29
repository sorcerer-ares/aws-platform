variable "pr_number" {
  description = "Pull request number for preview isolation"
  type        = string
}

variable "image_tag" {
  description = "Docker image tag (commit SHA)"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}
