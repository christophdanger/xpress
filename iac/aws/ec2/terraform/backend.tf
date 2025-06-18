# S3 bucket for application backups
resource "aws_s3_bucket" "app_backups" {
  bucket = "${var.project_name}-app-backups-${random_id.bucket_suffix.hex}"

  tags = {
    Name        = "Application Backups Bucket"
    Description = "S3 bucket for storing ERPNext application backups"
  }
}

# Generate a random suffix for unique resource naming
resource "random_id" "bucket_suffix" {
  byte_length = 4
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

# Lifecycle configuration for backups bucket
resource "aws_s3_bucket_lifecycle_configuration" "app_backups_lifecycle" {
  bucket = aws_s3_bucket.app_backups.id

  rule {
    id     = "backup_lifecycle"
    status = "Enabled"

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
  bucket = aws_s3_bucket.app_backups.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
