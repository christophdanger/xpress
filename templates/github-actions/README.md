# GitHub Actions Workflow Templates

This directory contains GitHub Actions workflow templates for automating ERPNext deployment and operations on AWS EC2.

## Available Templates

### Core Deployment Templates

#### `deploy-erpnext.yml.template`
- **Purpose**: Automated ERPNext deployment using Docker Compose with frappe_docker
- **Trigger Options**: Push to branch, manual trigger, or scheduled
- **Features**: 
  - Clones/updates frappe_docker repository
  - Configures environment variables
  - Deploys with HTTPS support
  - Site creation/migration
  - Backup script setup

#### `ssl-configuration.yml.template`  
- **Purpose**: SSL/TLS certificate configuration using Let's Encrypt and Traefik
- **Trigger Options**: Manual trigger or after deployment
- **Features**:
  - DNS validation
  - Certificate acquisition
  - Renewal monitoring
  - HTTPS redirection setup

### Operations Templates

#### `automated-backups.yml.template`
- **Purpose**: Automated backups to S3 with retention management
- **Trigger Options**: Scheduled (daily recommended) or manual
- **Features**:
  - Database and file backups
  - S3 upload with encryption
  - Backup verification
  - Metadata tracking
  - Retention policy enforcement

#### `infrastructure-monitoring.yml.template`
- **Purpose**: System health monitoring and alerting
- **Trigger Options**: Scheduled (every 6 hours recommended) or manual
- **Features**:
  - System resource monitoring
  - SSL certificate expiry checks
  - Backup status verification
  - Security monitoring
  - Status reporting

#### `disaster-recovery.yml.template`
- **Purpose**: Backup restoration and disaster recovery
- **Trigger Options**: Manual trigger only (requires confirmation)
- **Features**:
  - Multiple restore types (full, database-only, files-only)
  - Backup integrity verification
  - Safety confirmations
  - Rollback capabilities

## Setup Instructions

### 1. Copy Templates to Your Project

```bash
# Create workflows directory in your project
mkdir -p .github/workflows

# Copy desired templates
cp /path/to/xpress/templates/github-actions/deploy-erpnext.yml.template .github/workflows/deploy-erpnext.yml
cp /path/to/xpress/templates/github-actions/ssl-configuration.yml.template .github/workflows/ssl-configuration.yml
# ... copy other templates as needed
```

### 2. Configure GitHub Secrets

Add these secrets to your GitHub repository settings:

#### Required for All Workflows
- `AWS_ACCESS_KEY_ID`: AWS access key with appropriate permissions
- `AWS_SECRET_ACCESS_KEY`: AWS secret access key

#### Required for Deployment
- `LETSENCRYPT_EMAIL`: Email for Let's Encrypt certificate notifications
- `DB_PASSWORD`: MariaDB database password
- `ADMIN_PASSWORD`: ERPNext administrator password

#### Optional Configuration
- `BACKUP_RETENTION_DAYS`: Backup retention period (default: 30)
- `SITE_NAME`: ERPNext site name (default: derived from domain)

### 3. Customize Templates

#### Update Repository References
Replace placeholder repository references with your actual repositories:
```yaml
# Change this:
repository: 'your-username/your-erpnext-repo'

# To your actual repository:
repository: 'mycompany/mycompany-erpnext'
```

#### Update Infrastructure References
Ensure the workflows reference your Terraform infrastructure:
```yaml
# Update working directory if needed:
working-directory: ./iac/aws/ec2/terraform

# Update region if needed:
aws-region: us-east-1
```

#### Configure Domain and Email
```yaml
# In deploy-erpnext.yml:
env:
  DOMAIN: your-domain.com
  LETSENCRYPT_EMAIL: ${{ secrets.LETSENCRYPT_EMAIL }}
```

### 4. Validate Prerequisites

Before running workflows, ensure:
- [ ] AWS infrastructure is deployed via Terraform
- [ ] EC2 instance has proper IAM permissions
- [ ] Security groups allow HTTP/HTTPS traffic
- [ ] Domain DNS points to your EC2 instance
- [ ] All required GitHub secrets are configured

## Workflow Dependencies

### Execution Order
1. **Infrastructure**: Deploy using Terraform first
2. **Application**: Run `deploy-erpnext.yml`
3. **SSL**: Run `ssl-configuration.yml` (if using custom domain)
4. **Backups**: Enable `automated-backups.yml` schedule
5. **Monitoring**: Enable `infrastructure-monitoring.yml` schedule

### Dependencies Between Workflows
- SSL configuration requires successful application deployment
- Backup monitoring requires backup scripts to be configured
- Disaster recovery requires existing backups

## Customization Examples

### Custom Backup Schedule
```yaml
# In automated-backups.yml.template
on:
  schedule:
    # Run backups at 2 AM UTC daily
    - cron: '0 2 * * *'
  workflow_dispatch:
    inputs:
      backup_type:
        description: 'Type of backup'
        required: false
        default: 'full'
        type: choice
        options:
          - full
          - database-only
          - files-only
```

### Custom Monitoring Intervals
```yaml
# In infrastructure-monitoring.yml.template
on:
  schedule:
    # Monitor every 4 hours instead of 6
    - cron: '0 */4 * * *'
```

### Environment-Specific Deployment
```yaml
# In deploy-erpnext.yml.template
on:
  push:
    branches:
      - main      # Production deployments
      - develop   # Staging deployments
  workflow_dispatch:
    inputs:
      environment:
        description: 'Deployment environment'
        required: true
        default: 'staging'
        type: choice
        options:
          - staging
          - production
```

## Security Considerations

### AWS Permissions
The AWS credentials should have minimal required permissions:
- EC2: Start/stop instances, describe instances
- SSM: Session manager access
- S3: Read/write to backup bucket only
- CloudWatch: Write logs (optional)

### Secret Management
- Use GitHub's encrypted secrets
- Rotate AWS credentials regularly
- Use IAM roles when possible instead of access keys
- Never commit secrets to code

### Network Security
- Restrict EC2 security groups to necessary ports
- Use HTTPS for all external communications
- Implement proper firewall rules

## Troubleshooting

### Common Issues

#### Workflow Permissions
```yaml
# Add to workflow if needed:
permissions:
  contents: read
  actions: read
  security-events: write
```

#### AWS Authentication
```yaml
# Verify AWS credentials step:
- name: Configure AWS credentials
  uses: aws-actions/configure-aws-credentials@v2
  with:
    aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
    aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
    aws-region: us-east-1
```

#### Terraform State Access
Ensure the workflow can access Terraform state to get infrastructure information:
```yaml
- name: Get Terraform Outputs
  working-directory: ./iac/aws/ec2/terraform
  run: |
    terraform init
    terraform output -json > ../../../terraform-outputs.json
```

### Debug Steps
1. Enable debug logging: Add `ACTIONS_STEP_DEBUG: true` to secrets
2. Check AWS CLI configuration in workflow
3. Verify Terraform outputs are accessible
4. Test SSH/SSM connectivity manually
5. Check EC2 instance logs via CloudWatch

## Best Practices

### Workflow Design
- Make workflows idempotent
- Include comprehensive error handling
- Use meaningful step names and descriptions
- Add status reporting and notifications

### Security
- Use least-privilege AWS permissions
- Implement proper secret management
- Add security scanning steps
- Regular security audits

### Maintenance
- Keep workflows updated with latest actions
- Test workflows regularly
- Monitor workflow success rates
- Document any customizations

## Advanced Usage

### Multi-Environment Setup
Create separate workflow files for different environments:
- `.github/workflows/deploy-staging.yml`
- `.github/workflows/deploy-production.yml`

### Integration with External Systems
- Add notification steps for Slack/Teams
- Integrate with monitoring systems (Datadog, New Relic)
- Connect to ticketing systems (Jira, ServiceNow)

### Custom Backup Strategies
- Implement custom backup retention policies
- Add cross-region backup replication
- Integrate with external backup providers

## Contributing

When modifying these templates:
1. Test changes thoroughly
2. Update documentation
3. Follow established patterns
4. Consider backward compatibility
5. Submit changes as pull requests

## Support

For template-specific issues:
1. Check this documentation first
2. Review the workflow logs in GitHub Actions
3. Consult the main repository documentation
4. Check AWS CloudWatch logs for infrastructure issues
