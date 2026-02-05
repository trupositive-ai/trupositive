# Simple S3 bucket example with trupositive automatic tagging
# 
# Usage:
#   1. trupositive init
#   2. terraform init
#   3. terraform apply

terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
  
  # Git metadata variables provided by trupositive wrapper
  default_tags {
    tags = {
      git_sha    = var.git_sha
      git_branch = var.git_branch
      git_repo   = var.git_repo
      managed_by = "terraform"
      project    = "example"
    }
  }
}

# These variables are automatically populated by trupositive
variable "git_sha" {
  description = "Git commit SHA"
  type        = string
  default     = "unknown"
}

variable "git_branch" {
  description = "Git branch name"
  type        = string
  default     = "unknown"
}

variable "git_repo" {
  description = "Git repository URL"
  type        = string
  default     = "unknown"
}

# Get current AWS account ID
data "aws_caller_identity" "current" {}

# S3 bucket - automatically tagged via provider default_tags
resource "aws_s3_bucket" "example" {
  bucket = "trupositive-example-${data.aws_caller_identity.current.account_id}"
}

# Bucket versioning
resource "aws_s3_bucket_versioning" "example" {
  bucket = aws_s3_bucket.example.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Bucket encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "example" {
  bucket = aws_s3_bucket.example.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Outputs
output "bucket_name" {
  description = "Name of the created S3 bucket"
  value       = aws_s3_bucket.example.id
}

output "bucket_arn" {
  description = "ARN of the created S3 bucket"
  value       = aws_s3_bucket.example.arn
}

output "git_metadata" {
  description = "Git metadata used for tagging"
  value = {
    commit = var.git_sha
    branch = var.git_branch
    repo   = var.git_repo
  }
}
