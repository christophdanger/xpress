# GitHub Actions Workflow Templates

## Overview

This directory contains templates for GitHub Actions workflows that implement automated deployment and configuration for ERPNext on AWS EC2 infrastructure. These templates are designed to be copied and customized in your own projects, as this repository serves as a reference implementation library.

**Note**: The workflows in this repository have been moved to `/templates/github-actions/` as `.template` files. This ensures they don't run automatically in this reference repository but can be easily copied and adapted for your own projects.

## Available Workflow Templates

All workflow templates are located in `/templates/github-actions/` and include:

### User Story 2.1: Automated Application Deployment
- **Template**: `deploy-erpnext.yml.template`
- **Purpose**: Automatically deploy ERPNext application using Docker Compose with frappe_docker

### User Story 2.2: Automated SSL/TLS Configuration  
- **Template**: `ssl-configuration.yml.template`
- **Purpose**: Configure SSL/TLS certificates using Let's Encrypt and Traefik

### User Story 3.1: Automated Backups to S3
- **Template**: `automated-backups.yml.template`
- **Purpose**: Create automated backups of ERPNext data and store in S3

### Infrastructure Monitoring & Maintenance
- **Template**: `infrastructure-monitoring.yml.template`
- **Purpose**: Monitor system health, SSL status, backup status, and security

### Disaster Recovery & Restore
- **Template**: `disaster-recovery.yml.template`
- **Purpose**: Restore ERPNext from S3 backups with various restore options

## How to Use These Templates

1. **Copy templates to your project**: Copy the desired `.template` files from `/templates/github-actions/` to your project's `.github/workflows/` directory
2. **Remove .template extension**: Rename files to remove the `.template` suffix (e.g., `deploy-erpnext.yml`)
3. **Customize for your environment**: Update repository references, secret names, and configuration values
4. **Configure GitHub Secrets**: Set up the required secrets in your GitHub repository settings
5. **Test workflows**: Run workflows manually first to ensure they work in your environment

## Architecture Patterns

### Deployment Architecture
The deployment follows the frappe_docker single-server pattern with:
- **Traefik**: Reverse proxy with automatic SSL certificate management
- **ERPNext/Frappe**: Application containers (backend, frontend, workers, scheduler)
- **MariaDB**: Database container
- **Redis**: Cache and queue containers
- **Docker Compose**: Container orchestration with override files for different configurations

### Key Design Principles

1. **Infrastructure as Code**: All deployments use Terraform outputs to get instance information
2. **Secure Access**: Uses AWS SSM Session Manager instead of SSH
3. **Idempotent Operations**: All workflows can be run multiple times safely
4. **Comprehensive Logging**: Detailed output for troubleshooting and auditing
5. **Standardized Configuration**: Uses environment files and compose overrides
6. **Automated SSL**: Let's Encrypt integration with automatic renewal
7. **Backup Strategy**: Automated daily backups with configurable retention

## Workflow Details

### 1. Automated ERPNext Deployment

**Template**: `/templates/github-actions/deploy-erpnext.yml.template`

**Features**:
- Clones/updates frappe_docker repository
- Configures environment variables for ERPNext
- Deploys using Docker Compose with HTTPS support
- Creates or migrates sites automatically
- Sets up automated backup scripts
- Configures monitoring scripts

**Key Configuration**:
```yaml
# Generated docker-compose configuration
docker compose --project-name erpnext \
  --env-file ~/gitops/erpnext.env \
  -f compose.yaml \
  -f overrides/compose.mariadb.yaml \
  -f overrides/compose.redis.yaml \
  -f overrides/compose.https.yaml \
  config > ~/gitops/docker-compose.yml
```

**Environment Variables Required**:
- `LETSENCRYPT_EMAIL`: Email for Let's Encrypt notifications
- `DB_PASSWORD`: Database password
- `ADMIN_PASSWORD`: ERPNext admin password

### 2. SSL/TLS Configuration

**Template**: `/templates/github-actions/ssl-configuration.yml.template`

**Features**:
- Validates DNS configuration
- Configures Traefik for SSL termination
- Obtains Let's Encrypt certificates
- Sets up certificate monitoring
- Handles certificate renewal

**DNS Requirements**:
- Domain must point to the EC2 instance's Elastic IP
- Ports 80 and 443 must be accessible
- Let's Encrypt rate limits apply

### 3. Automated Backups to S3

**Template**: `/templates/github-actions/automated-backups.yml.template`

**Features**:
- Multiple backup types (full, database-only, files-only)
- Backup metadata with JSON structure
- S3 lifecycle management
- Backup verification
- Automatic cleanup based on retention policy

**Backup Structure**:
```
S3 Bucket:
├── backups/
│   └── erpnext_backup_YYYYMMDD_HHMMSS.tar.gz
└── metadata/
    └── backup_metadata_YYYYMMDD_HHMMSS.json
```

### 4. Infrastructure Monitoring

**Template**: `/templates/github-actions/infrastructure-monitoring.yml.template`

**Monitoring Components**:
- **System Health**: CPU, memory, disk usage, container status
- **SSL Status**: Certificate expiry, HTTPS connectivity
- **Backup Status**: Recent backup verification, S3 accessibility
- **Security Status**: System updates, firewall, suspicious processes

**Status Levels**:
- `HEALTHY`: All systems operational
- `WARNING`: Minor issues detected
- `CRITICAL`: Immediate attention required
- `DOWN`: Service unavailable

### 5. Disaster Recovery & Restore

**Template**: `/templates/github-actions/disaster-recovery.yml.template`

**Restore Types**:
- `full-restore`: Complete restoration of database and files
- `database-only`: Database restoration only
- `files-only`: Files restoration only
- `test-restore`: Backup integrity verification without changes

**Safety Features**:
- Requires explicit confirmation
- Validates backup ID format
- Verifies backup exists before proceeding
- Creates backup of current data before restore

## Configuration Management

### Environment Files
All workflows use standardized environment files stored in `~/gitops/`:
- `erpnext.env`: Main ERPNext configuration
- `docker-compose.yml`: Generated compose configuration

### Secrets Management
GitHub Secrets required:
- `AWS_ACCESS_KEY_ID`: AWS credentials
- `AWS_SECRET_ACCESS_KEY`: AWS credentials
- `LETSENCRYPT_EMAIL`: Email for SSL certificates
- `DB_PASSWORD`: Database password
- `ADMIN_PASSWORD`: ERPNext admin password

### Docker Compose Overrides
The deployment uses frappe_docker override files:
- `compose.yaml`: Base configuration
- `overrides/compose.mariadb.yaml`: MariaDB service
- `overrides/compose.redis.yaml`: Redis services
- `overrides/compose.https.yaml`: HTTPS/SSL configuration

## Backup and Recovery Strategy

### Backup Schedule
- **Automated**: Daily at 2:00 AM UTC via GitHub Actions
- **Manual**: On-demand via workflow dispatch
- **Retention**: Configurable (default 30 days)

### Backup Contents
- ERPNext database (compressed SQL dump)
- Site files (private/public directories)
- Site configurations
- System configurations
- Backup metadata

### Recovery Options
- Full site restoration
- Selective database or files restoration
- Test restoration for backup verification
- Cross-site restoration capabilities

## Monitoring and Alerting

### Automated Monitoring
- Health checks every 6 hours
- SSL certificate monitoring (weekly)
- Backup verification after each backup
- Security monitoring

### Status Reporting
- GitHub Actions summary with status indicators
- Detailed logs for troubleshooting
- Infrastructure status dashboard in workflow summaries

### Alert Conditions
- SSL certificate expiring within 30 days
- Backup failures or missing backups
- System resource exhaustion
- Container failures

## Best Practices

### Security
- No SSH access required (uses SSM)
- Secrets stored in GitHub Secrets
- SSL/TLS enforced for all connections
- Regular security monitoring

### Reliability
- Idempotent operations
- Comprehensive error handling
- Rollback capabilities
- Backup verification

### Maintainability
- Standardized workflows
- Comprehensive documentation
- Clear status reporting
- Modular design

### Scalability
- Backend-agnostic workflow design
- Configuration-driven deployments
- Reusable components
- Cloud-native patterns

## Troubleshooting

### Common Issues

1. **SSL Certificate Failures**
   - Verify DNS points to correct IP
   - Check firewall rules for ports 80/443
   - Review Let's Encrypt rate limits

2. **Deployment Failures**
   - Check Docker service status
   - Verify environment variables
   - Review container logs

3. **Backup Failures**
   - Verify S3 bucket permissions
   - Check disk space on instance
   - Review cron job configuration

4. **Restore Failures**
   - Verify backup file integrity
   - Check database credentials
   - Ensure sufficient disk space

### Diagnostic Commands

```bash
# Check container status
docker compose --project-name erpnext -f ~/gitops/docker-compose.yml ps

# View container logs
docker compose --project-name erpnext -f ~/gitops/docker-compose.yml logs [service]

# Check SSL certificate
/opt/erpnext/check-ssl.sh

# Verify latest backup
/opt/erpnext/verify-last-backup.sh

# Manual backup
/opt/erpnext/backup-to-s3.sh
```

## Future Enhancements

### Planned Improvements
1. **Multi-site Management**: Enhanced workflows for multiple ERPNext sites
2. **Blue-Green Deployments**: Zero-downtime deployment strategies  
3. **Performance Monitoring**: Application-level metrics and alerting
4. **Integration Testing**: Automated testing of deployed applications
5. **Cost Optimization**: Automated resource scaling and optimization

### Extension Points
- Custom notification integrations (Slack, email, PagerDuty)
- Additional backup storage providers
- Enhanced monitoring with CloudWatch/Prometheus
- Custom deployment strategies for different environments
- Integration with external CI/CD systems

## Conclusion

Epic 2 provides a comprehensive, production-ready deployment and operations platform for ERPNext on AWS. The workflows are designed to be reliable, secure, and maintainable while following cloud-native best practices. The modular design allows for easy extension and adaptation to different requirements and environments.
