# Outputs for the main infrastructure

# Networking outputs (User Story 1.2)
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_id" {
  description = "ID of the public subnet"
  value       = aws_subnet.public.id
}

output "public_subnet_cidr" {
  description = "CIDR block of the public subnet"
  value       = aws_subnet.public.cidr_block
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.main.id
}

# Application backup bucket outputs
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
