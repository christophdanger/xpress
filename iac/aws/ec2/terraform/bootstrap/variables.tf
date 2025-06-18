# Variables for the bootstrap configuration
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

variable "enable_public_access_block" {
  description = "Whether to enable S3 public access block (may not be available in all AWS accounts)"
  type        = bool
  default     = false
}
