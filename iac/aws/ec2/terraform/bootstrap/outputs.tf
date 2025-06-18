# Outputs for the bootstrap configuration (simplified - no DynamoDB)
output "terraform_state_bucket_name" {
  description = "Name of the S3 bucket for Terraform state"
  value       = aws_s3_bucket.terraform_state.bucket
}

output "terraform_state_bucket_arn" {
  description = "ARN of the S3 bucket for Terraform state"
  value       = aws_s3_bucket.terraform_state.arn
}

output "aws_region" {
  description = "AWS region where resources are deployed"
  value       = var.aws_region
}

# Generate backend configuration for main infrastructure (without DynamoDB locking)
output "backend_config" {
  description = "Backend configuration for the main infrastructure"
  value = <<EOF
terraform {
  backend "s3" {
    bucket  = "${aws_s3_bucket.terraform_state.bucket}"
    key     = "terraform.tfstate"
    region  = "${var.aws_region}"
    encrypt = true
  }
}
EOF
}
