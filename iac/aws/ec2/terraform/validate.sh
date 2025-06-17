#!/bin/bash

# Script to validate the AWS EC2 Terraform configuration
# This ensures the code is syntactically correct before deployment
# Part of: iac/aws/ec2/terraform - AWS EC2-based ERPNext staging environment

set -e

echo "🔍 Validating AWS EC2 Terraform Configuration"
echo "============================================="

# Change to terraform directory
cd "$(dirname "$0")"

# Check if Terraform is installed
if ! command -v terraform &> /dev/null; then
    echo "❌ Terraform is not installed or not in PATH"
    echo "Please install Terraform: https://learn.hashicorp.com/tutorials/terraform/install-cli"
    exit 1
fi

# Check Terraform version
TERRAFORM_VERSION=$(terraform version -json | jq -r '.terraform_version')
echo "✅ Terraform version: $TERRAFORM_VERSION"

# Initialize Terraform (this downloads providers)
echo "📦 Initializing Terraform..."
terraform init -backend=false

# Format check
echo "🎨 Checking code formatting..."
if ! terraform fmt -check=true -diff=true; then
    echo "❌ Code formatting issues found. Run 'terraform fmt' to fix."
    exit 1
fi
echo "✅ Code formatting is correct"

# Validate configuration
echo "🔍 Validating configuration syntax..."
if terraform validate; then
    echo "✅ Terraform configuration is valid"
else
    echo "❌ Terraform configuration validation failed"
    exit 1
fi

# Security scan (if tfsec is available)
if command -v tfsec &> /dev/null; then
    echo "🔒 Running security scan..."
    tfsec .
    echo "✅ Security scan completed"
else
    echo "ℹ️  tfsec not found - skipping security scan"
    echo "   Install tfsec for security scanning: https://github.com/aquasecurity/tfsec"
fi

echo ""
echo "🎉 All validation checks passed!"
echo "The Terraform configuration is ready for deployment."
