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
