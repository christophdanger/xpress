# Variables for User Stories 1.1 & 1.2
# Core project and networking variables only

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

# ===========================================
# NETWORKING VARIABLES (User Story 1.2)
# ===========================================
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
