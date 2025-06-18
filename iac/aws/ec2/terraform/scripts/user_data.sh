#!/bin/bash
# User data script for ERPNext EC2 instance initialization
# This script sets up the basic environment for ERPNext deployment

set -e

# Update system packages
yum update -y

# Install required packages
yum install -y \
    docker \
    docker-compose \
    git \
    awscli \
    htop \
    wget \
    curl \
    unzip

# Start and enable Docker
systemctl start docker
systemctl enable docker

# Add ec2-user to docker group
usermod -aG docker ec2-user

# Install Docker Compose (latest version)
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Create application directory
mkdir -p /opt/erpnext
chown ec2-user:ec2-user /opt/erpnext

# Clone frappe_docker repository
cd /opt/erpnext
git clone https://github.com/frappe/frappe_docker.git
chown -R ec2-user:ec2-user frappe_docker

# Create environment file
cat > /opt/erpnext/.env << EOF
# ERPNext Configuration
ERPNEXT_VERSION=v14
FRAPPE_VERSION=v14
MYSQL_ROOT_PASSWORD=$(openssl rand -base64 32)
LETSENCRYPT_EMAIL=admin@example.com
BACKUP_BUCKET=${backup_bucket}
PROJECT_NAME=${project_name}
EOF

# Set permissions
chown ec2-user:ec2-user /opt/erpnext/.env
chmod 600 /opt/erpnext/.env

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
