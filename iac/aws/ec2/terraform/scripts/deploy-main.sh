#!/bin/bash

# Script to deploy the main AWS EC2 infrastructure
# This script implements the main infrastructure AFTER bootstrap is complete
# Part of: iac/aws/ec2/terraform - AWS EC2-based ERPNext staging environment

set -e

echo "🚀 Deploying AWS EC2 Main Infrastructure"
echo "========================================"

# Check if bootstrap has been completed
if [ ! -f "backend-config.tf" ]; then
    echo "❌ Backend configuration not found!"
    echo ""
    echo "You need to run the bootstrap process first:"
    echo "1. cd bootstrap/"
    echo "2. ./deploy-bootstrap.sh"
    echo "3. cd .. (back to this directory)"
    echo "4. Run this script again"
    echo ""
    exit 1
fi

echo "✅ Backend configuration found"

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

# Initialize Terraform with remote backend
echo "📦 Initializing Terraform with remote backend..."
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
    echo "🛠️  Applying main infrastructure..."
    terraform apply tfplan
    
    # Get outputs
    echo ""
    echo "📊 Deployment Results:"
    echo "====================="
    BACKUP_BUCKET=$(terraform output -raw app_backups_bucket_name)
    
    echo "Backup Bucket: $BACKUP_BUCKET"
    echo ""
    
    echo "✅ Main infrastructure deployed successfully!"
    echo ""
    echo "🎉 User Story 1.1 Complete!"
    echo ""
    echo "📋 Next Steps:"
    echo "1. Proceed with User Story 1.2: Foundational Networking (VPC)"
    echo "2. Then User Story 1.3: Self-Contained EC2 Instance"
    echo ""
    
    # Clean up plan file
    rm -f tfplan
else
    echo "❌ Deployment cancelled"
    rm -f tfplan
    exit 1
fi
