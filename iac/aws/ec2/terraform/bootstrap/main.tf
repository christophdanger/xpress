# Simplified Terraform backend infrastructure
# Creates only S3 bucket for state storage (no DynamoDB due to permission limitations)

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "xpress-erpnext"
      Environment = "staging"
      ManagedBy   = "terraform"
      Owner       = "devops"
      Purpose     = "terraform-backend"
    }
  }
}
