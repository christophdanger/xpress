# Outputs for the main infrastructure
output "app_backups_bucket_name" {
  description = "Name of the S3 bucket for application backups"
  value       = aws_s3_bucket.app_backups.bucket
}

output "app_backups_bucket_arn" {
  description = "ARN of the S3 bucket for application backups"
  value       = aws_s3_bucket.app_backups.arn
}

output "aws_region" {
  description = "AWS region where resources are deployed"
  value       = var.aws_region
}
