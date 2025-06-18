# Variables for the Terraform configuration
variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "xpress-erpnext"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "staging"
}

variable "backup_retention_days" {
  description = "Number of days to retain backups"
  type        = number
  default     = 365
}

# Networking variables (User Story 1.2)
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "enable_public_access_block" {
  description = "Whether to enable S3 public access block (may not be available in all AWS accounts)"
  type        = bool
  default     = false
}
