#!/bin/bash

# Script to deploy the Terraform backend
# This script sets up the S3 bucket, DynamoDB table, and IAM policies for Terraform state management
# Part of: iac/aws/ec2/terraform - AWS EC2-based ERPNext staging environment

set -e

echo "🚀 Deploying Terraform Backend"
echo "========================================"

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

# Change to bootstrap directory
cd "$(dirname "$0")/../bootstrap"

echo "📁 Working directory: $(pwd)"

# Initialize Terraform
echo "📦 Initializing Terraform..."
terraform init

# Validate configuration
echo "🔍 Validating Terraform configuration..."
terraform validate

# Plan the deployment
echo "📋 Planning Terraform backend deployment..."
terraform plan -out=tfplan

# Ask for confirmation
echo ""
read -p "🤔 Do you want to apply these changes? (y/N): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    # Apply the configuration
    echo "🛠️  Applying Terraform backend..."
    terraform apply tfplan

    # Get outputs
    echo ""
    echo "📊 Backend Deployment Results:"
    echo "============================="
    STATE_BUCKET=$(terraform output -raw state_bucket_name)
    LOCK_TABLE=$(terraform output -raw lock_table_name)

    echo "State Bucket: $STATE_BUCKET"
    echo "Lock Table: $LOCK_TABLE"
    echo ""

    echo "✅ Terraform backend deployed successfully!"
    echo ""

    # Clean up plan file
    rm -f tfplan
else
    echo "❌ Deployment cancelled"
    rm -f tfplan
    exit 1
fi