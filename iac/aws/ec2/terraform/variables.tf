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

# ===========================================
# COMPUTE VARIABLES (User Story 1.3)
# ===========================================
variable "instance_type" {
  description = "EC2 instance type for ERPNext"
  type        = string
  default     = "t3.medium"
}

variable "root_volume_size" {
  description = "Size of the root EBS volume in GB"
  type        = number
  default     = 20
}

variable "ami_id" {
  description = "AMI ID for the EC2 instance (Amazon Linux 2)"
  type        = string
  default     = "ami-02b3c03c6fadb6e2c" # Latest Amazon Linux 2 AMI in us-east-1
}
