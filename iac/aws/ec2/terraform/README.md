# AWS EC2 Terraform Infrastructure for ERPNext Staging Environment

This directory contains the Terraform configuration for deploying a cost-effective, self-contained staging environment for the Frappe/ERPNext application on AWS EC2.

## Directory Structure Context

This is part of the `xpress` Infrastructure as Code (IaC) repository structure:

```
iac/
├── aws/
│   ├── ec2/
│   │   └── terraform/          # ← You are here
│   ├── ecs/
│   │   └── terraform/          # Future: ECS-based deployment
│   └── eks/
│       └── terraform/          # Future: EKS-based deployment
├── azure/
│   ├── vm/
│   │   └── terraform/          # Future: Azure VM deployment
│   └── aks/
│       └── terraform/          # Future: Azure AKS deployment
└── gcp/
    ├── compute/
    │   └── terraform/          # Future: GCP Compute deployment
    └── gke/
        └── terraform/          # Future: GCP GKE deployment
```

## Overview

This Terraform configuration implements the infrastructure requirements defined in the Product Requirements Document (PRD) for EC2 Staging Environment deployment on AWS.

## Phase 1: Secure Terraform State Backend (User Story 1.1)

### What This Phase Implements

✅ **S3 bucket for Terraform state storage** with:
- Versioning enabled for state history
- Server-side encryption (AES256)
- Public access blocked for security

✅ **DynamoDB table for state locking** to prevent concurrent modifications

✅ **S3 bucket for application backups** with:
- Versioning enabled
- Lifecycle policies for cost optimization
- Automatic transition to cheaper storage tiers

### Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     AWS Account                             │
│                                                             │
│  ┌─────────────────┐  ┌──────────────────┐  ┌─────────────┐ │
│  │   S3 Bucket     │  │   DynamoDB       │  │ S3 Bucket   │ │
│  │ (Terraform      │  │   Table          │  │ (App        │ │
│  │  State)         │  │ (State Lock)     │  │  Backups)   │ │
│  │                 │  │                  │  │             │ │
│  │ ✓ Versioning    │  │ ✓ Pay-per-req    │  │ ✓ Lifecycle │ │
│  │ ✓ Encryption    │  │ ✓ Hash key:      │  │ ✓ Tiering   │ │
│  │ ✓ Private       │  │   LockID         │  │ ✓ Private   │ │
│  └─────────────────┘  └──────────────────┘  └─────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

## Prerequisites

Before deploying this infrastructure, ensure you have:

1. **AWS CLI installed and configured**
   ```bash
   aws configure
   # OR set environment variables:
   # export AWS_ACCESS_KEY_ID=your_access_key
   # export AWS_SECRET_ACCESS_KEY=your_secret_key
   # export AWS_DEFAULT_REGION=us-east-1
   ```

2. **Terraform installed** (version >= 1.0)
   ```bash
   # Check version
   terraform version
   ```

3. **Appropriate AWS permissions** for your user/role:
   - S3: CreateBucket, PutBucketVersioning, PutBucketEncryption, etc.
   - DynamoDB: CreateTable, DescribeTable, etc.
   - IAM: List and describe permissions for resource tagging

## Deployment Steps

## Deployment Steps

### Prerequisites
- AWS CLI configured with appropriate credentials
- Terraform >= 1.0 installed

### Step 1: Bootstrap (Backend Infrastructure)

Create the S3 bucket and DynamoDB table for Terraform state:

```bash
cd bootstrap/
./deploy-bootstrap.sh
cd ..
```

### Step 2: Main Infrastructure

Deploy the application infrastructure with remote backend:

```bash
./deploy-main.sh
```

**Important**: The bootstrap step creates the backend infrastructure separately to avoid the circular dependency problem of creating and using an S3 bucket as a backend in the same configuration.

See [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) for detailed explanation and troubleshooting.

## File Structure

```
iac/aws/ec2/terraform/
├── bootstrap/                  # Backend infrastructure (S3 + DynamoDB)
│   ├── main.tf                 # Provider configuration
│   ├── variables.tf            # Bootstrap variables
│   ├── backend.tf              # S3 and DynamoDB resources
│   ├── outputs.tf              # Backend configuration generation
│   └── deploy-bootstrap.sh     # Bootstrap deployment script
├── main.tf                     # Main provider configuration
├── variables.tf                # Input variables
├── backend.tf                  # Application resources (S3 backups)
├── outputs.tf                  # Output values
├── backend-config.tf           # Generated backend config (after bootstrap)
├── deploy-main.sh              # Main deployment script
├── DEPLOYMENT_GUIDE.md         # Step-by-step deployment guide
└── README.md                   # This file
```

## Configuration Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `aws_region` | AWS region for resources | `us-east-1` | No |
| `project_name` | Name of the project | `xpress-erpnext` | No |
| `environment` | Environment name | `staging` | No |
| `backup_retention_days` | Days to retain backups | `30` | No |

### Customizing Variables

Create a `terraform.tfvars` file to override defaults:

```hcl
aws_region = "us-west-2"
project_name = "my-erpnext"
environment = "staging"
backup_retention_days = 90
```

## Outputs

After deployment, the following outputs will be available:

- `terraform_state_bucket_name`: Name of the S3 bucket storing Terraform state
- `terraform_state_lock_table_name`: Name of the DynamoDB table for state locking
- `app_backups_bucket_name`: Name of the S3 bucket for application backups
- AWS region and ARNs of all created resources

## Security Features

### S3 Buckets
- **Server-side encryption** with AES256
- **Versioning enabled** for state history and backup retention
- **Public access blocked** to prevent unauthorized access
- **Lifecycle policies** for cost optimization

### DynamoDB Table
- **Pay-per-request billing** to minimize costs
- **Encrypted at rest** (AWS managed keys)

### Resource Tagging
All resources are tagged with:
- Project name
- Environment
- Managed by Terraform
- Owner information

## Cost Optimization

The infrastructure is designed for cost efficiency:

1. **DynamoDB**: Pay-per-request billing (no reserved capacity)
2. **S3 Lifecycle**: Automatic transition to cheaper storage classes
3. **Minimal resources**: Only essential components for state management

Estimated monthly cost: **< $5** for typical staging workloads.

## Troubleshooting

### Common Issues

1. **AWS credentials not configured**:
   ```
   Error: NoCredentialProviders: no valid providers in chain
   ```
   **Solution**: Run `aws configure` or set environment variables

2. **Insufficient permissions**:
   ```
   Error: AccessDenied: User is not authorized to perform...
   ```
   **Solution**: Ensure your AWS user/role has the necessary permissions

3. **Bucket name conflicts**:
   ```
   Error: BucketAlreadyExists
   ```
   **Solution**: The random suffix should prevent this, but you can modify the `project_name` variable

### Getting Help

If you encounter issues:

1. Check the [Terraform AWS Provider documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
2. Review AWS CloudTrail logs for permission issues
3. Validate your Terraform syntax: `terraform validate`

## Next Steps

After completing User Story 1.1, proceed with:

- **User Story 1.2**: Foundational Networking (VPC)
- **User Story 1.3**: Self-Contained EC2 Instance
- **Epic 2**: Automated Deployment & Configuration

## Security Considerations

- Store AWS credentials securely (use IAM roles when possible)
- Never commit `terraform.tfvars` with sensitive values
- Regularly rotate AWS access keys
- Monitor AWS CloudTrail for unexpected API calls
