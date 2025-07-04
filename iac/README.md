# Infrastructure as Code (IaC) Directory

This directory contains Infrastructure as Code configurations for deploying the Frappe/ERPNext application across multiple cloud providers and deployment patterns.

## Directory Structure

```
iac/
├── aws/                        # Amazon Web Services deployments
│   ├── ec2/                    # EC2-based single-instance deployment
│   │   └── terraform/          # ✅ IMPLEMENTED - Staging environment
│   ├── ecs/                    # ECS-based container deployment (Future)
│   │   └── terraform/          # 🔄 PLANNED - Production-ready containers
│   ├── eks/                    # EKS-based Kubernetes deployment (Future)
│   │   └── terraform/          # 🔄 PLANNED - Scalable Kubernetes
│   └── README.md               # AWS-specific documentation
├── azure/                      # Microsoft Azure deployments (Future)
│   ├── vm/                     # Virtual Machine deployment
│   │   └── terraform/          # 🔄 PLANNED - Azure VM staging
│   ├── aks/                    # Azure Kubernetes Service
│   │   └── terraform/          # 🔄 PLANNED - Azure Kubernetes
│   └── README.md               # Azure-specific documentation
├── gcp/                        # Google Cloud Platform deployments (Future)
│   ├── compute/                # Compute Engine deployment
│   │   └── terraform/          # 🔄 PLANNED - GCP VM staging
│   ├── gke/                    # Google Kubernetes Engine
│   │   └── terraform/          # 🔄 PLANNED - GCP Kubernetes
│   └── README.md               # GCP-specific documentation
└── README.md                   # This file
```

## Current Implementation Status

### ✅ **AWS EC2 - Staging Environment (COMPLETED)**
- **Path**: `iac/aws/ec2/terraform/`
- **Status**: User Story 1.1 complete - Secure Terraform State Backend
- **Purpose**: Cost-effective, single-instance staging environment
- **Use Cases**: Development, testing, small-scale production
- **Cost**: < $5/month
- **Documentation**: [AWS EC2 README](aws/ec2/terraform/README.md)

### 🔄 **Future Implementations (PLANNED)**

#### AWS ECS - Production Containers
- **Path**: `iac/aws/ecs/terraform/`
- **Purpose**: Production-ready containerized deployment
- **Features**: Auto-scaling, load balancing, multi-AZ
- **Use Cases**: Production workloads, high availability

#### AWS EKS - Kubernetes Platform
- **Path**: `iac/aws/eks/terraform/`
- **Purpose**: Full Kubernetes orchestration
- **Features**: Microservices, advanced scaling, service mesh
- **Use Cases**: Enterprise-scale, multi-tenant

#### Multi-Cloud Support
- **Azure VM**: Alternative to AWS EC2
- **Azure AKS**: Alternative to AWS EKS
- **GCP Compute**: Alternative to AWS EC2
- **GCP GKE**: Alternative to AWS EKS

## Deployment Pattern Comparison

| Pattern | Cost | Complexity | Scalability | Availability | Use Case |
|---------|------|------------|-------------|--------------|----------|
| EC2 Single | $ | Low | Limited | Basic | Development/Staging |
| ECS Containers | $$ | Medium | High | High | Production |
| EKS/AKS/GKE | $$$ | High | Very High | Very High | Enterprise |

## Getting Started

### Prerequisites
- Cloud provider account (AWS, Azure, or GCP)
- Terraform >= 1.0
- Cloud CLI tools (aws-cli, az-cli, or gcloud)
- Git

### Quick Start - AWS EC2 Staging
```bash
# Navigate to AWS EC2 deployment
cd iac/aws/ec2/terraform/

# Deploy the infrastructure
./deploy-backend.sh

# Validate configuration
./validate.sh
```

## Design Principles

### 1. **Separation of Concerns**
Each cloud provider and deployment pattern is isolated in its own directory structure.

### 2. **Consistency**
All deployments follow the same structural patterns and naming conventions.

### 3. **Scalability**
Clear migration paths from simple (EC2) to complex (Kubernetes) deployments.

### 4. **Security First**
All deployments include security best practices from the ground up.

### 5. **Cost Optimization**
Each pattern is optimized for its intended use case and cost profile.

## Contributing

When adding new deployment patterns:

1. **Follow the directory structure**: `iac/{cloud}/{service}/terraform/`
2. **Include comprehensive documentation**: README.md with deployment instructions
3. **Implement security best practices**: Encryption, access controls, monitoring
4. **Provide cost estimates**: Clear understanding of operational costs
5. **Include validation scripts**: Automated testing and validation

## Support Matrix

| Cloud Provider | Single Instance | Containers | Kubernetes | Status |
|----------------|-----------------|------------|------------|--------|
| AWS | ✅ EC2 | 🔄 ECS | 🔄 EKS | Partial |
| Azure | 🔄 VM | 🔄 Container Instances | 🔄 AKS | Planned |
| GCP | 🔄 Compute Engine | 🔄 Cloud Run | 🔄 GKE | Planned |

## Related Documentation

- [Product Requirements Document](../docs/aws/prd-deployment-aws-ec2-phase-1.md)
- [AWS EC2 Implementation](aws/ec2/terraform/README.md)
- [Project Overview](../README.md)
