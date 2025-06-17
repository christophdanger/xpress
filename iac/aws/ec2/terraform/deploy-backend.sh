#!/bin/bash

# Script to deploy the Terraform state backend infrastructure for AWS EC2 deployment
# This script implements User Story 1.1: Secure Terraform State Backend
# Part of: iac/aws/ec2/terraform - AWS EC2-based ERPNext staging environment

set -e

echo "🚀 Deploying AWS EC2 Terraform State Backend Infrastructure"
echo "=========================================================="

# Check if AWS CLI is configured
if ! aws sts get-caller-identity &> /dev/null; then
    echo "❌ AWS CLI is not configured or credentials are invalid"
    echo "Please run 'aws configure' or set AWS credentials environment variables"
    exit 1
fi

# Get current AWS account and region
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION=$(aws configure get region || echo "us-east-1")

echo "✅ AWS Account ID: $AWS_ACCOUNT_ID"
echo "✅ AWS Region: $AWS_REGION"
echo ""

# Change to terraform directory
cd "$(dirname "$0")"

echo "📁 Working directory: $(pwd)"

# Initialize Terraform
echo "📦 Initializing Terraform..."
terraform init

# Validate configuration
echo "🔍 Validating Terraform configuration..."
terraform validate

# Plan the deployment
echo "📋 Planning Terraform deployment..."
terraform plan -out=tfplan

# Ask for confirmation
echo ""
read -p "🤔 Do you want to apply these changes? (y/N): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    # Apply the configuration
    echo "🛠️  Applying Terraform configuration..."
    terraform apply tfplan
    
    # Get outputs
    echo ""
    echo "📊 Deployment Results:"
    echo "====================="
    BUCKET_NAME=$(terraform output -raw terraform_state_bucket_name)
    TABLE_NAME=$(terraform output -raw terraform_state_lock_table_name)
    BACKUP_BUCKET=$(terraform output -raw app_backups_bucket_name)
    
    echo "S3 State Bucket: $BUCKET_NAME"
    echo "DynamoDB Lock Table: $TABLE_NAME"
    echo "Backup Bucket: $BACKUP_BUCKET"
    echo ""
    
    # Create the backend configuration file
    echo "📝 Creating backend configuration file..."
    cat > backend-config.tf << EOF
# Backend configuration for remote state
# Generated automatically by deploy-backend.sh

terraform {
  backend "s3" {
    bucket         = "$BUCKET_NAME"
    key            = "terraform.tfstate"
    region         = "$AWS_REGION"
    dynamodb_table = "$TABLE_NAME"
    encrypt        = true
  }
}
EOF
    
    echo "✅ Backend configuration created: backend-config.tf"
    echo ""
    echo "🎉 State backend infrastructure deployed successfully!"
    echo ""
    echo "📋 Next Steps:"
    echo "1. Run 'terraform init -migrate-state' to migrate state to remote backend"
    echo "2. Commit the backend-config.tf file to version control"
    echo "3. Remove the local terraform.tfstate file after successful migration"
    echo ""
    
    # Clean up plan file
    rm -f tfplan
else
    echo "❌ Deployment cancelled"
    rm -f tfplan
    exit 1
fi
