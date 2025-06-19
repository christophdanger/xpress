# AWS EC2 Standalone ERPNext Example

This example demonstrates how to use the xpress reference implementation to deploy ERPNext on a single AWS EC2 instance.

## Project Structure

When using xpress templates in your own project, organize your repository like this:

```
your-erpnext-project/
├── .github/
│   └── workflows/
│       ├── deploy-erpnext.yml              # Copied from template
│       ├── ssl-configuration.yml           # Copied from template
│       ├── automated-backups.yml           # Copied from template
│       ├── infrastructure-monitoring.yml   # Copied from template
│       └── disaster-recovery.yml           # Copied from template
├── iac/
│   └── aws/
│       └── ec2/
│           └── terraform/                  # Copied from xpress
├── docs/
│   └── deployment/
└── README.md
```

## Setup Steps

### 1. Copy Infrastructure Code

Copy the Terraform infrastructure from xpress:

```bash
# From the xpress repository
cp -r iac/aws/ec2/terraform/ /path/to/your-project/iac/aws/ec2/
```

### 2. Copy Workflow Templates

Copy and rename the GitHub Actions templates:

```bash
# Create workflows directory
mkdir -p .github/workflows

# Copy templates and remove .template extension
cp /path/to/xpress/templates/github-actions/deploy-erpnext.yml.template .github/workflows/deploy-erpnext.yml
cp /path/to/xpress/templates/github-actions/ssl-configuration.yml.template .github/workflows/ssl-configuration.yml
cp /path/to/xpress/templates/github-actions/automated-backups.yml.template .github/workflows/automated-backups.yml
cp /path/to/xpress/templates/github-actions/infrastructure-monitoring.yml.template .github/workflows/infrastructure-monitoring.yml
cp /path/to/xpress/templates/github-actions/disaster-recovery.yml.template .github/workflows/disaster-recovery.yml
```

### 3. Configure GitHub Secrets

Add these secrets to your GitHub repository settings:

#### Required Secrets
- `AWS_ACCESS_KEY_ID`: AWS access key
- `AWS_SECRET_ACCESS_KEY`: AWS secret key
- `LETSENCRYPT_EMAIL`: Email for SSL certificates
- `DB_PASSWORD`: Database password (generate a strong password)
- `ADMIN_PASSWORD`: ERPNext admin password

#### Optional Secrets
- `BACKUP_RETENTION_DAYS`: Backup retention (default: 30)

### 4. Customize Configuration

#### Update Domain Configuration
In `.github/workflows/deploy-erpnext.yml`:

```yaml
env:
  DOMAIN: your-domain.com  # Replace with your domain
  SITE_NAME: your-site     # Replace with your site name
```

#### Update AWS Region (if needed)
In workflow files and Terraform variables:

```yaml
# GitHub Actions workflows
env:
  AWS_REGION: us-west-2  # Change if needed

# terraform/variables.tf
variable "aws_region" {
  default = "us-west-2"  # Change if needed
}
```

### 5. Deploy Infrastructure

```bash
cd iac/aws/ec2/terraform
./deploy-backend.sh
./deploy-main.sh
```

### 6. Deploy Application

Push code to trigger deployment or run workflows manually:

```bash
git add .
git commit -m "Initial ERPNext deployment configuration"
git push origin main
```

## Customization Examples

### Production Environment

For production, consider these modifications:

#### Enhanced Backup Schedule
```yaml
# In automated-backups.yml
on:
  schedule:
    # Backup twice daily
    - cron: '0 2,14 * * *'
```

#### Enhanced Monitoring
```yaml
# In infrastructure-monitoring.yml
on:
  schedule:
    # Monitor every 2 hours
    - cron: '0 */2 * * *'
```

#### Multi-Environment Deployment
Create separate workflow files:
- `.github/workflows/deploy-staging.yml`
- `.github/workflows/deploy-production.yml`

### Development Environment

For development, you might want:

#### On-Demand Deployment Only
```yaml
# Remove schedule triggers, keep only:
on:
  workflow_dispatch:
```

#### Simplified Backup
```yaml
# Backup only on manual trigger
on:
  workflow_dispatch:
```

## Domain Configuration

### DNS Setup
1. Point your domain to the EC2 instance's Elastic IP
2. Create A record: `your-domain.com` → `EC2_ELASTIC_IP`
3. Wait for DNS propagation (up to 24 hours)

### SSL Certificate
Run the SSL workflow after DNS is configured:
1. Go to GitHub Actions
2. Run "SSL Configuration" workflow
3. Verify HTTPS access to your domain

## Monitoring and Maintenance

### Regular Tasks
- Monitor backup success in GitHub Actions
- Check SSL certificate expiry (automated alerts)
- Review system health reports
- Update dependencies regularly

### Emergency Procedures
- Use disaster recovery workflow for restoring from backups
- Monitor infrastructure via GitHub Actions workflows
- Check AWS CloudWatch for system metrics

## Cost Optimization

### EC2 Instance Sizing
- **Development**: t3.micro or t3.small
- **Small Production**: t3.medium
- **Larger Production**: t3.large or t3.xlarge

### Storage Optimization
- Use gp3 volumes for better cost/performance
- Implement backup lifecycle policies
- Monitor and clean up old Docker images

### Networking
- Use CloudFront for better global performance
- Consider Reserved Instances for long-term use

## Security Best Practices

### AWS IAM
- Use least-privilege permissions
- Rotate access keys regularly
- Enable CloudTrail for audit logging

### Application Security
- Use strong passwords for all accounts
- Enable two-factor authentication
- Regular security updates via monitoring workflow

### Network Security
- Restrict security group rules to minimum required
- Use VPC with proper subnet configuration
- Enable GuardDuty for threat detection

## Troubleshooting

### Common Issues

#### Deployment Failures
1. Check AWS credentials and permissions
2. Verify Terraform state is accessible
3. Check EC2 instance status
4. Review workflow logs in GitHub Actions

#### SSL Issues
1. Verify DNS points to correct IP
2. Check firewall rules (ports 80, 443)
3. Review Let's Encrypt rate limits
4. Check domain ownership

#### Backup Failures
1. Verify S3 bucket permissions
2. Check disk space on EC2 instance
3. Review backup script logs
4. Validate AWS credentials

### Getting Help
1. Check xpress documentation: [xpress repository](https://github.com/your-org/xpress)
2. Review AWS CloudWatch logs
3. Check Frappe/ERPNext community forums
4. Review GitHub Actions workflow logs

## License

This example configuration is based on the xpress reference implementation. Please review and comply with the licensing terms of:
- xpress (reference implementation)
- frappe_docker
- Frappe Framework
- ERPNext

## Contributing

To contribute improvements to this example:
1. Test changes thoroughly
2. Update documentation
3. Submit pull requests to the main xpress repository
4. Follow security best practices
