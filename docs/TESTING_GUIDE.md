# Complete Testing Guide: ERPNext Deployment with xpress

This comprehensive guide walks you through testing the complete ERPNext deployment workflow using xpress templates, from local development to production deployment.

## Table of Contents

1. [Overview and Prerequisites](#overview-and-prerequisites)
2. [Understanding Frappe Docker Development](#understanding-frappe-docker-development)
3. [Setting Up Your Development Environment](#setting-up-your-development-environment)
4. [Infrastructure Deployment](#infrastructure-deployment)
5. [GitHub Actions Configuration](#github-actions-configuration)
6. [Testing User Story 2.1: Automated Deployment](#testing-user-story-21-automated-deployment)
7. [Testing User Story 2.2: SSL Configuration](#testing-user-story-22-ssl-configuration)
8. [Production Image Building and Deployment](#production-image-building-and-deployment)
9. [End-to-End Testing](#end-to-end-testing)
10. [Troubleshooting Guide](#troubleshooting-guide)

---

## Overview and Prerequisites

### What This Guide Covers

This guide provides a complete workflow for:
- Setting up local development with frappe_docker
- Building custom ERPNext applications
- Testing infrastructure deployment with Terraform
- Configuring automated deployment via GitHub Actions
- SSL certificate setup and management
- Production deployment and monitoring

### Prerequisites

Before starting, ensure you have:

#### AWS Requirements
- ✅ AWS Account with appropriate permissions
- ✅ AWS CLI configured locally
- ✅ Domain name (for SSL testing)
- ✅ Basic understanding of AWS EC2, S3, and IAM

#### GitHub Requirements
- ✅ GitHub account and repository for your project
- ✅ Basic understanding of GitHub Actions
- ✅ Git configured locally

#### Local Development Environment
- ✅ Docker and Docker Compose installed
- ✅ Terraform installed (latest version)
- ✅ VS Code with Dev Containers extension
- ✅ Node.js and Python (for local development)

#### Knowledge Requirements
- ✅ Basic command line proficiency
- ✅ Understanding of git workflows
- ✅ Familiarity with Docker concepts

---

## Understanding Frappe Docker Development

### The Three Modes Explained

Frappe development involves three distinct modes that often cause confusion:

#### 1. 🔧 Development Mode (VS Code Dev Containers)
- **Purpose**: Local development with live code changes
- **Environment**: Inside VS Code dev containers
- **Use Case**: Writing and testing custom Frappe apps
- **Key Feature**: Hot reloading, immediate feedback
- **Limitation**: ❌ Cannot build production images

#### 2. 🏗️ Production Image Building Mode
- **Purpose**: Creating deployable Docker images
- **Environment**: Host machine (outside dev containers)
- **Use Case**: Building images with custom apps for deployment
- **Key Feature**: Creates immutable deployment artifacts
- **Requirement**: ✅ Must be done outside dev containers

#### 3. 🚀 Production Deployment Mode
- **Purpose**: Running applications on servers
- **Environment**: Production servers or CI/CD
- **Use Case**: Actual deployment to staging/production
- **Key Feature**: Uses pre-built images from mode #2

### File System and Git Repository Structure

Understanding where your code lives is crucial:

```
Host Machine:
~/projects/my-erpnext-project/
├── frappe_docker/                     # Cloned frappe_docker repo
│   ├── .devcontainer/                # Dev container configuration
│   ├── development/                  # 🔑 MOUNTED into container
│   │   └── frappe-bench/            # Created by bench init
│   │       └── apps/
│   │           └── my_custom_app/   # ✅ Your app with git repo
│   ├── compose.yaml                 # Production compose file
│   └── images/                      # For building custom images
├── deployment-config/               # xpress templates and config
└── README.md
```

**Key Insight**: The `development/` directory is mounted into the dev container, so anything you create there persists on your host machine and can have its own git repository.

---

## Setting Up Your Development Environment

### Step 1: Create Project Structure

```bash
# Create your main project directory
mkdir -p ~/projects/my-erpnext-project
cd ~/projects/my-erpnext-project

# Create subdirectories
mkdir -p frappe_docker
mkdir -p deployment-config
mkdir -p custom-apps
```

### Step 2: Set Up Frappe Docker

```bash
# Clone frappe_docker for development
cd ~/projects/my-erpnext-project
git clone https://github.com/frappe/frappe_docker.git frappe_docker/
cd frappe_docker

# Set up dev container configuration
cp -R devcontainer-example .devcontainer
cp -R development/vscode-example development/.vscode

# Create persistent development directories
mkdir -p development/frappe-bench
mkdir -p development/custom-apps
```

### Step 3: Copy xpress Templates

```bash
# Copy infrastructure and workflow templates
cd ~/projects/my-erpnext-project/deployment-config

# Copy Terraform infrastructure
mkdir -p iac/aws/ec2
cp -r /path/to/xpress/iac/aws/ec2/terraform/ iac/aws/ec2/

# Copy GitHub Actions templates
mkdir -p .github/workflows
cp /path/to/xpress/templates/github-actions/deploy-erpnext.yml.template .github/workflows/deploy-erpnext.yml
cp /path/to/xpress/templates/github-actions/ssl-configuration.yml.template .github/workflows/ssl-configuration.yml
cp /path/to/xpress/templates/github-actions/automated-backups.yml.template .github/workflows/automated-backups.yml
cp /path/to/xpress/templates/github-actions/infrastructure-monitoring.yml.template .github/workflows/infrastructure-monitoring.yml
cp /path/to/xpress/templates/github-actions/disaster-recovery.yml.template .github/workflows/disaster-recovery.yml
```

### Step 4: Initialize Development Environment

```bash
# Open frappe_docker in VS Code
cd ~/projects/my-erpnext-project/frappe_docker
code .

# VS Code will prompt to reopen in container - click "Reopen in Container"
# This starts the development environment with all services
```

### Step 5: Set Up Frappe Bench (Inside Dev Container)

Once VS Code opens in the dev container:

```bash
# Initialize bench (this persists because development/ is mounted)
cd /workspace/development
bench init --skip-redis-config-generation --frappe-branch version-14 frappe-bench
cd frappe-bench

# Configure for containerized services
bench set-config -g db_host mariadb
bench set-config -g redis_cache redis://redis-cache:6379
bench set-config -g redis_queue redis://redis-queue:6379
bench set-config -g redis_socketio redis://redis-queue:6379

# Remove redis from Procfile (using containers instead)
sed -i '/redis/d' ./Procfile

# Create your development site
bench new-site --no-mariadb-socket development.localhost
# Enter password: 123 (mariadb root password)

# Enable developer mode
bench --site development.localhost set-config developer_mode 1
bench --site development.localhost clear-cache

# Install ERPNext
bench get-app --branch version-14 erpnext
bench --site development.localhost install-app erpnext
```

### Step 6: Create Your Custom App

```bash
# Still inside dev container
cd /workspace/development/frappe-bench

# Create a new custom app
bench new-app my_custom_app
# Follow the prompts for app details

# Install the app on your site
bench --site development.localhost install-app my_custom_app

# Set up git repository for your custom app
cd apps/my_custom_app
git init
git add .
git commit -m "Initial custom app setup"

# Connect to your GitHub repository
git remote add origin https://github.com/your-username/my-custom-app.git
git push -u origin main
```

### Step 7: Daily Development Workflow

```bash
# Start your development day:
cd ~/projects/my-erpnext-project/frappe_docker
code .  # Opens in dev container

# Inside the dev container:
cd /workspace/development/frappe-bench
bench start

# Access ERPNext at: http://development.localhost:8000
# Login: Administrator / password-you-set

# Make changes to your custom app:
# Edit files in: /workspace/development/frappe-bench/apps/my_custom_app/

# Commit changes:
cd /workspace/development/frappe-bench/apps/my_custom_app
git add .
git commit -m "Add new feature"
git push
```

---

## Infrastructure Deployment

### Step 1: Test Terraform Locally

```bash
# Exit VS Code dev container and work on host machine
cd ~/projects/my-erpnext-project/deployment-config/iac/aws/ec2/terraform

# Initialize Terraform
terraform init
terraform validate
terraform plan
```

### Step 2: Deploy S3 Backend

```bash
# Deploy the Terraform backend
./scripts/deploy-backend.sh

# This creates:
# - S3 bucket for Terraform state
# - DynamoDB table for state locking
# - IAM policies for access
```

### Step 3: Deploy Main Infrastructure

```bash
# Deploy the main infrastructure
./scripts/deploy-main.sh

# This creates:
# - VPC and networking components
# - EC2 instance with security group
# - S3 bucket for backups
# - IAM roles and policies
```

### Step 4: Verify Infrastructure

```bash
# Check deployment outputs
terraform output

# Test access to EC2 instance
aws ssm start-session --target $(terraform output -raw instance_id)

# Verify all resources
terraform state list
```

---

## GitHub Actions Configuration

### Step 1: Create Your Deployment Repository

```bash
# Create a new repository for your deployment configuration
cd ~/projects/my-erpnext-project/deployment-config
git init
git add .
git commit -m "Initial deployment configuration"

# Push to your GitHub repository
git remote add origin https://github.com/your-username/my-erpnext-deployment.git
git push -u origin main
```

### Step 2: Configure GitHub Secrets

In your GitHub repository settings → Secrets and variables → Actions, add:

```
AWS_ACCESS_KEY_ID=AKIA...
AWS_SECRET_ACCESS_KEY=...
LETSENCRYPT_EMAIL=your-email@domain.com
DB_PASSWORD=your-strong-database-password-here
ADMIN_PASSWORD=your-erpnext-admin-password-here
BACKUP_RETENTION_DAYS=30
```

### Step 3: Customize Workflows for Your Environment

Edit `.github/workflows/deploy-erpnext.yml`:

```yaml
env:
  DOMAIN: your-domain.com
  SITE_NAME: your-site
  FRAPPE_DOCKER_REPO: your-username/frappe_docker
  AWS_REGION: us-east-1
```

### Step 4: Test AWS Access

Create a simple test workflow:

```yaml
# .github/workflows/test-aws.yml
name: Test AWS Access
on: workflow_dispatch

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - name: Configure AWS
        uses: aws-actions/configure-aws-credentials@v2
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: us-east-1
      
      - name: Test AWS CLI
        run: aws sts get-caller-identity
```

---

## Testing User Story 2.1: Automated Deployment

### Step 1: Prepare for Testing

```bash
# Ensure your frappe_docker repository is accessible
git clone https://github.com/your-username/frappe_docker.git /tmp/test-frappe-docker
cd /tmp/test-frappe-docker
ls compose.yaml overrides/  # Verify required files exist

# Ensure Terraform outputs are accessible
cd ~/projects/my-erpnext-project/deployment-config/iac/aws/ec2/terraform
terraform output -json > terraform-outputs.json
```

### Step 2: Run Deployment Workflow

1. Go to your GitHub repository
2. Navigate to Actions tab
3. Select "Deploy ERPNext" workflow
4. Click "Run workflow"
5. Monitor execution in real-time

### Step 3: Monitor Deployment Progress

Key stages to watch for:
- ✅ AWS credentials configuration
- ✅ Terraform outputs retrieval
- ✅ EC2 connection via Session Manager
- ✅ frappe_docker repository clone
- ✅ Docker Compose configuration
- ✅ ERPNext site creation and installation

### Step 4: Verify Deployment Success

```bash
# Connect to your EC2 instance
aws ssm start-session --target $(terraform output -raw instance_id)

# On the EC2 instance, check containers
sudo docker ps
sudo docker compose --project-name erpnext ps

# Test HTTP access (before SSL)
curl -I http://$(terraform output -raw elastic_ip)
```

### Step 5: Access Your ERPNext Instance

```bash
# Get your instance's public IP
terraform output elastic_ip

# Access ERPNext in browser:
# http://YOUR-EC2-PUBLIC-IP
# Login: Administrator / your-admin-password
```

---

## Testing User Story 2.2: SSL Configuration

### Step 1: Configure DNS

```bash
# Point your domain to the EC2 instance
# Create an A record:
# your-domain.com → YOUR-EC2-ELASTIC-IP

# Verify DNS propagation
nslookup your-domain.com
dig your-domain.com
```

### Step 2: Run SSL Configuration Workflow

1. Go to GitHub Actions → "SSL Configuration"
2. Click "Run workflow"
3. Enter your domain name when prompted
4. Monitor the execution

### Step 3: Verify SSL Setup

```bash
# Test HTTPS access
curl -I https://your-domain.com

# Check certificate details
echo | openssl s_client -connect your-domain.com:443 -servername your-domain.com

# Verify certificate issuer (should be Let's Encrypt)
echo | openssl s_client -connect your-domain.com:443 2>/dev/null | openssl x509 -noout -issuer
```

### Step 4: Test ERPNext over HTTPS

```bash
# Access your ERPNext instance
# https://your-domain.com
# Should automatically redirect from HTTP to HTTPS
```

---

## Production Image Building and Deployment

### Step 1: Understanding Image Building

When you're ready to deploy your custom app to production, you need to build a custom Docker image that includes your app.

### Step 2: Exit Dev Container Mode

```bash
# Close VS Code dev container
# Open terminal on your host machine
cd ~/projects/my-erpnext-project/frappe_docker
```

### Step 3: Create Production Apps Configuration

```bash
# Create apps.json with your custom app
cat > apps.json << EOF
[
  {
    "url": "https://github.com/frappe/erpnext",
    "branch": "version-14"
  },
  {
    "url": "https://github.com/your-username/my-custom-app",
    "branch": "main"
  }
]
EOF
```

### Step 4: Build Custom Production Image

```bash
# Build custom image with your apps
export APPS_JSON_BASE64=$(base64 -w 0 apps.json)

docker build \
  --build-arg APPS_JSON_BASE64=$APPS_JSON_BASE64 \
  --tag your-dockerhub-username/custom-erpnext:v1.0.0 \
  --file images/custom/Containerfile .
```

### Step 5: Test Production Image Locally

```bash
# Create a test configuration
cat > docker-compose.test.yml << EOF
version: "3.7"
services:
  backend:
    image: your-dockerhub-username/custom-erpnext:v1.0.0
    environment:
      - DB_HOST=localhost
      - REDIS_CACHE=redis://localhost:6379
    ports:
      - "8000:8000"
EOF

# Test the image
docker-compose -f docker-compose.test.yml up
```

### Step 6: Push to Registry

```bash
# Login to Docker Hub
docker login

# Push your custom image
docker push your-dockerhub-username/custom-erpnext:v1.0.0
```

### Step 7: Update Deployment Configuration

Update your GitHub Actions workflow to use the custom image:

```yaml
# In .github/workflows/deploy-erpnext.yml
env:
  CUSTOM_ERPNEXT_IMAGE: your-dockerhub-username/custom-erpnext:v1.0.0

# Add step to configure custom image
- name: Configure custom ERPNext image
  run: |
    echo "ERPNEXT_IMAGE=${{ env.CUSTOM_ERPNEXT_IMAGE }}" >> ~/gitops/erpnext.env
```

---

## End-to-End Testing

### Complete Workflow Test

```bash
# 1. Verify infrastructure is deployed
cd ~/projects/my-erpnext-project/deployment-config/iac/aws/ec2/terraform
terraform output

# 2. Run deployment workflow (GitHub Actions)
# 3. Configure DNS for your domain
# 4. Run SSL configuration workflow (GitHub Actions)
# 5. Test complete functionality

# Test ERPNext API access
curl -c cookies.txt -b cookies.txt \
  -d "cmd=login&usr=Administrator&pwd=YOUR_ADMIN_PASSWORD" \
  https://your-domain.com/api/method/login

# Test authenticated API call
curl -c cookies.txt -b cookies.txt \
  https://your-domain.com/api/resource/User
```

### Backup and Monitoring Setup

```bash
# Test backup workflow manually
# Go to GitHub Actions → "Automated Backups" → Run workflow

# Verify backup was created
aws s3 ls $(terraform output -raw s3_bucket_name)/backups/

# Test monitoring workflow
# Go to GitHub Actions → "Infrastructure Monitoring" → Run workflow
```

---

## Troubleshooting Guide

### Common Development Issues

#### Issue: Changes disappear when restarting dev container
**Solution**: Ensure you're working in the mounted directory
```bash
# ✅ Work here (persists):
cd /workspace/development/frappe-bench/apps/my_custom_app

# ❌ Don't work here (ephemeral):
cd /home/frappe/frappe-bench/apps/my_custom_app
```

#### Issue: Git doesn't work in dev container
**Solution**: Configure git in the container
```bash
git config --global user.email "you@example.com"
git config --global user.name "Your Name"
```

#### Issue: Can't build production images in dev container
**Solution**: Exit dev container and build on host machine
```bash
# Exit VS Code dev container mode
# Open regular terminal on host
cd ~/projects/my-erpnext-project/frappe_docker
docker build ...
```

### Infrastructure Issues

#### Issue: Terraform state lock
```bash
# If state is locked, unlock it
terraform force-unlock LOCK_ID
```

#### Issue: AWS permissions errors
```bash
# Verify AWS credentials
aws sts get-caller-identity

# Check IAM policies match requirements in documentation
```

### Deployment Issues

#### Issue: GitHub Actions can't access Terraform outputs
```bash
# Verify terraform init works in workflow environment
cd iac/aws/ec2/terraform
terraform init
terraform output
```

#### Issue: SSL certificate fails
```bash
# Check DNS propagation
dig your-domain.com

# Verify domain points to correct IP
nslookup your-domain.com

# Check Let's Encrypt rate limits
# Consider using staging environment for testing
```

#### Issue: Docker containers won't start
```bash
# Check container logs
sudo docker compose logs
sudo docker compose logs backend

# Check system resources
free -h
df -h
```

### Debug Commands

```bash
# Check system status on EC2
aws ssm start-session --target INSTANCE_ID
sudo systemctl status docker
sudo docker system df
sudo docker ps -a

# Check ERPNext logs
sudo docker exec -it erpnext-backend-1 tail -f /home/frappe/frappe-bench/logs/web.log

# Test network connectivity
curl -I http://localhost:8000
curl -I https://your-domain.com
```

## Success Criteria

Your complete workflow is successful when:

- ✅ **Development Environment**: Can create and modify custom apps in dev containers
- ✅ **Infrastructure**: Terraform deploys all AWS resources successfully
- ✅ **GitHub Actions**: All workflows run without errors
- ✅ **HTTP Access**: ERPNext accessible via HTTP
- ✅ **HTTPS Access**: SSL certificate configured and ERPNext accessible via HTTPS
- ✅ **Custom Apps**: Your custom applications deploy and function correctly
- ✅ **Backups**: Automated backup workflow creates S3 backups
- ✅ **Monitoring**: Infrastructure monitoring reports system health
- ✅ **Production Images**: Can build and deploy custom Docker images

## Next Steps

After successful testing:

1. **Document Environment-Specific Configuration**: Keep notes on customizations
2. **Set Up Automated Schedules**: Configure backup and monitoring schedules
3. **Implement Security Hardening**: Review and enhance security measures
4. **Plan Production Deployment**: Prepare for actual production deployment
5. **Set Up Monitoring and Alerting**: Implement comprehensive monitoring
6. **Create Disaster Recovery Plan**: Document recovery procedures
7. **Performance Optimization**: Monitor and optimize resource usage

This completes your comprehensive testing of the xpress ERPNext deployment workflow. You now have a fully functional development-to-production pipeline for ERPNext deployment on AWS.
