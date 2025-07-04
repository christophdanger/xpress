#!/bin/bash

# Bootstrap script to create Terraform backend infrastructure
# This creates ONLY the S3 bucket and DynamoDB table needed for remote state

set -e

echo "🏗️  Bootstrap: Creating Terraform Backend Infrastructure"
echo "======================================================"

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
cd "$(dirname "$0")"

echo "📁 Working directory: $(pwd)"

# Initialize Terraform (no backend needed for bootstrap)
echo "📦 Initializing Terraform..."
terraform init

# Validate configuration
echo "🔍 Validating Terraform configuration..."
terraform validate

# Plan the deployment
echo "📋 Planning bootstrap deployment..."
terraform plan -out=bootstrap.tfplan

# Ask for confirmation
echo ""
read -p "🤔 Do you want to create the backend infrastructure? (y/N): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    # Apply the configuration
    echo "🛠️  Creating backend infrastructure..."
    terraform apply bootstrap.tfplan
    
    # Get outputs
    echo ""
    echo "📊 Bootstrap Results:"
    echo "===================="
    BUCKET_NAME=$(terraform output -raw terraform_state_bucket_name)
    TABLE_NAME=$(terraform output -raw terraform_state_lock_table_name)
    
    echo "S3 State Bucket: $BUCKET_NAME"
    echo "DynamoDB Lock Table: $TABLE_NAME"
    echo ""
    
    # Create the backend configuration file for main infrastructure
    echo "📝 Creating backend configuration for main infrastructure..."
    terraform output -raw backend_config > ../backend-config.tf
    
    echo "✅ Backend configuration created: ../backend-config.tf"
    echo ""
    echo "🎉 Bootstrap completed successfully!"
    echo ""
    echo "📋 Next Steps:"
    echo "1. cd .. (go back to main terraform directory)"
    echo "2. Run 'terraform init' to initialize with remote backend"
    echo "3. Continue with main infrastructure deployment"
    echo ""
    
    # Clean up plan file
    rm -f bootstrap.tfplan
else
    echo "❌ Bootstrap cancelled"
    rm -f bootstrap.tfplan
    exit 1
fi
