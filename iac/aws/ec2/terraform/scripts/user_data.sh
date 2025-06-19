#!/bin/bash
# User data script for ERPNext EC2 instance
# Basic system setup and preparation for ERPNext installation

# Update system packages
yum update -y

# Install basic utilities
yum install -y \
    curl \
    wget \
    git \
    htop \
    unzip \
    vim

# Create a log file for user data execution
LOG_FILE="/var/log/user-data.log"
exec > >(tee -a $LOG_FILE)
exec 2>&1

echo "$(date): Starting user data script execution"
echo "Project: ${project_name}"
echo "Environment: ${environment}"

# Install Docker (for future ERPNext containerized deployment)
yum install -y docker
systemctl enable docker
systemctl start docker

# Add ec2-user to docker group
usermod -aG docker ec2-user

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Install AWS CLI v2 (for backup operations)
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install
rm -rf aws awscliv2.zip

# Install jq for JSON processing
yum install -y jq

# Create directory structure for ERPNext
mkdir -p /opt/erpnext
chown ec2-user:ec2-user /opt/erpnext

# Create gitops directory for configuration management
mkdir -p /home/ec2-user/gitops
chown ec2-user:ec2-user /home/ec2-user/gitops

# Set hostname
hostnamectl set-hostname ${project_name}-${environment}

# Create initial environment template
cat > /opt/erpnext/.env << 'EOF'
# ERPNext Environment Configuration
# This file will be updated by deployment workflows
PROJECT_NAME=${project_name}
ENVIRONMENT=${environment}
EOF

# Set permissions
chown ec2-user:ec2-user /opt/erpnext/.env
chmod 600 /opt/erpnext/.env

echo "$(date): User data script execution completed"
echo "Instance ready for ERPNext deployment"

# Create backup script
cat > /opt/erpnext/backup.sh << 'EOF'
#!/bin/bash
# Backup script for ERPNext data

source /opt/erpnext/.env

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/tmp/backup_$TIMESTAMP"
mkdir -p $BACKUP_DIR

# Export database
docker exec $(docker ps -q -f name=mysql) mysqldump -u root -p$MYSQL_ROOT_PASSWORD --all-databases > $BACKUP_DIR/database.sql

# Backup file storage
docker cp $(docker ps -q -f name=erpnext):/home/frappe/frappe-bench/sites $BACKUP_DIR/

# Create tarball
cd /tmp
tar -czf backup_$TIMESTAMP.tar.gz backup_$TIMESTAMP/

# Upload to S3
aws s3 cp backup_$TIMESTAMP.tar.gz s3://$BACKUP_BUCKET/backups/

# Cleanup
rm -rf $BACKUP_DIR backup_$TIMESTAMP.tar.gz

echo "Backup completed: backup_$TIMESTAMP.tar.gz"
EOF

chmod +x /opt/erpnext/backup.sh
chown ec2-user:ec2-user /opt/erpnext/backup.sh

# Setup cron job for daily backups at 2 AM
echo "0 2 * * * /opt/erpnext/backup.sh >> /var/log/erpnext-backup.log 2>&1" | crontab -u ec2-user -

# Create log file
touch /var/log/erpnext-backup.log
chown ec2-user:ec2-user /var/log/erpnext-backup.log

# Signal completion
echo "ERPNext EC2 initialization completed at $(date)" > /opt/erpnext/init-complete.log

# Log the completion
logger "ERPNext EC2 instance initialization completed successfully"
