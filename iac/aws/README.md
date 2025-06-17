# AWS Infrastructure as Code

This directory contains Terraform configurations for deploying Frappe/ERPNext on Amazon Web Services (AWS).

## Available Deployment Patterns

### ✅ **EC2 Single Instance** (`ec2/terraform/`)
**Status**: Implemented (User Story 1.1 complete)

A cost-effective, self-contained staging environment running on a single EC2 instance.

**Features**:
- Single EC2 instance with EBS storage
- Docker Compose for application stack
- Let's Encrypt SSL certificates
- Automated backups to S3
- Systems Manager (SSM) access

**Use Cases**:
- Development environments
- Staging/testing
- Small-scale production (< 100 users)
- Cost-sensitive deployments

**Estimated Cost**: < $5/month

**Quick Start**:
```bash
cd ec2/terraform/
./deploy-backend.sh
```

### 🔄 **ECS Fargate** (`ecs/terraform/`)
**Status**: Planned

Production-ready containerized deployment using AWS ECS with Fargate.

**Planned Features**:
- ECS Fargate for serverless containers
- Application Load Balancer (ALB)
- RDS for managed database
- ElastiCache for Redis
- EFS for shared file storage
- Auto Scaling based on metrics
- Multi-AZ deployment

**Use Cases**:
- Production workloads
- Medium to large-scale (100-10k users)
- Require high availability
- Need managed services

**Estimated Cost**: $50-200/month

### 🔄 **EKS Kubernetes** (`eks/terraform/`)
**Status**: Planned

Enterprise-grade Kubernetes deployment using Amazon EKS.

**Planned Features**:
- Amazon EKS cluster
- Kubernetes ingress controllers
- Horizontal Pod Autoscaler (HPA)
- Cluster Autoscaler
- AWS Load Balancer Controller
- Container insights monitoring
- Service mesh (Istio) ready

**Use Cases**:
- Enterprise deployments
- Large-scale (10k+ users)
- Multi-tenant requirements
- Microservices architecture
- Advanced DevOps workflows

**Estimated Cost**: $150-500+/month

## Migration Paths

### From EC2 to ECS
1. Export application data from EC2 deployment
2. Deploy ECS infrastructure
3. Import data to managed RDS instance
4. Update DNS to point to ALB
5. Decommission EC2 resources

### From ECS to EKS
1. Package applications as Helm charts
2. Deploy EKS cluster
3. Migrate workloads using blue-green deployment
4. Update ingress configuration
5. Decommission ECS resources

## AWS Services Used

### Common Services (All Patterns)
- **IAM**: Identity and access management
- **VPC**: Virtual private cloud networking
- **S3**: Object storage for backups and static assets
- **Route 53**: DNS management
- **CloudWatch**: Monitoring and logging
- **Systems Manager**: Secure access and configuration

### EC2 Pattern
- **EC2**: Virtual machines
- **EBS**: Block storage
- **Elastic IP**: Static IP addresses

### ECS Pattern
- **ECS**: Container orchestration
- **Fargate**: Serverless containers
- **ALB**: Application load balancer
- **RDS**: Managed database
- **ElastiCache**: Managed Redis
- **EFS**: Managed file system

### EKS Pattern
- **EKS**: Managed Kubernetes
- **ECR**: Container registry
- **ALB**: Advanced load balancing
- **EBS CSI**: Persistent volumes
- **EFS CSI**: Shared file systems

## Security Considerations

### Network Security
- Private subnets for application components
- NAT Gateway for outbound internet access
- Security Groups with least privilege access
- Network ACLs for additional layer

### Data Security
- Encryption in transit (TLS/SSL)
- Encryption at rest (EBS, RDS, S3)
- Regular automated backups
- Cross-region backup replication

### Access Security
- IAM roles with minimal permissions
- No SSH access (SSM Session Manager)
- Multi-factor authentication
- Regular credential rotation

### Compliance
- CloudTrail for audit logging
- Config for compliance monitoring
- GuardDuty for threat detection
- Security Hub for centralized security

## Cost Optimization

### EC2 Pattern
- Spot instances for non-critical workloads
- Reserved instances for predictable usage
- EBS GP3 volumes for cost-effective storage
- S3 Intelligent Tiering for backups

### ECS Pattern
- Fargate Spot for development environments
- Reserved capacity for production
- RDS Reserved instances
- CloudWatch log retention policies

### EKS Pattern
- Spot instances for worker nodes
- Cluster Autoscaler for dynamic sizing
- Vertical Pod Autoscaler for resource optimization
- Karpenter for advanced node provisioning

## Monitoring and Observability

### Metrics
- CloudWatch metrics for infrastructure
- Application-specific metrics
- Custom dashboards
- Automated alerting

### Logging
- CloudWatch Logs for centralized logging
- Log aggregation and analysis
- Log retention policies
- Structured logging

### Tracing
- AWS X-Ray for distributed tracing
- Performance monitoring
- Request flow analysis
- Error tracking

## Getting Started

1. **Prerequisites**:
   ```bash
   # Install AWS CLI
   curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
   unzip awscliv2.zip
   sudo ./aws/install
   
   # Configure AWS credentials
   aws configure
   ```

2. **Choose your deployment pattern**:
   - Start with EC2 for development/staging
   - Move to ECS for production workloads
   - Consider EKS for enterprise requirements

3. **Deploy the infrastructure**:
   ```bash
   cd {pattern}/terraform/
   ./deploy-backend.sh
   ```

## Support and Documentation

- [AWS EC2 Documentation](ec2/terraform/README.md)
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

---

**Last Updated**: June 17, 2025  
**Maintained by**: DevOps Team
