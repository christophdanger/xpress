# User Story 1.2: Foundational Networking (VPC)
# Creates a simple VPC with a single public subnet for the ERPNext staging environment

# Get available availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

# VPC with non-default CIDR block
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.project_name}-vpc"
    Description = "VPC for ERPNext staging environment"
  }
}

# Internet Gateway for public subnet connectivity
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.project_name}-igw"
    Description = "Internet Gateway for ERPNext staging environment"
  }
}

# Single public subnet (as per requirements)
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.project_name}-public-subnet"
    Description = "Public subnet for ERPNext staging environment"
    Type        = "Public"
  }
}

# Route table for public subnet
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  # Route to Internet Gateway for internet access
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name        = "${var.project_name}-public-rt"
    Description = "Route table for public subnet"
  }
}

# Associate public subnet with public route table
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Generate a random suffix for unique resource naming (for backup bucket)
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# S3 bucket for application backups (User Story 3.1 preparation)
resource "aws_s3_bucket" "app_backups" {
  bucket = "${var.project_name}-app-backups-${random_id.bucket_suffix.hex}"

  tags = {
    Name        = "Application Backups Bucket"
    Description = "S3 bucket for storing ERPNext application backups"
  }
}

# Enable versioning on the backups bucket
resource "aws_s3_bucket_versioning" "app_backups_versioning" {
  bucket = aws_s3_bucket.app_backups.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Enable server-side encryption for the backups bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "app_backups_encryption" {
  bucket = aws_s3_bucket.app_backups.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

# Lifecycle configuration for backups bucket (cost optimization)
resource "aws_s3_bucket_lifecycle_configuration" "app_backups_lifecycle" {
  bucket = aws_s3_bucket.app_backups.id

  rule {
    id     = "backup_lifecycle"
    status = "Enabled"
    
    # Apply to all objects in the bucket
    filter {
      prefix = ""
    }

    # Transition to IA after 30 days
    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    # Transition to Glacier Instant Retrieval after 90 days
    transition {
      days          = 90
      storage_class = "GLACIER_IR"
    }

    # Delete after retention period
    expiration {
      days = var.backup_retention_days
    }

    # Clean up incomplete multipart uploads
    abort_incomplete_multipart_upload {
      days_after_initiation = 1
    }
  }
}

# Block public access to the backups bucket
resource "aws_s3_bucket_public_access_block" "app_backups_pab" {
  count  = var.enable_public_access_block ? 1 : 0
  bucket = aws_s3_bucket.app_backups.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
