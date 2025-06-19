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
│   │   └── frappe-bench/            # ⚠️ Created by 'bench init' (don't create manually)
│   │       └── apps/
│   │           ├── frappe/          # Standard frappe framework
│   │           ├── erpnext/         # Standard erpnext app
│   │           └── my_custom_app/   # ✅ Your app with its own git repo
│   ├── compose.yaml                 # Production compose file
│   └── images/                      # For building custom images
├── deployment-config/               # xpress templates and config
│   └── .git/                       # Main deployment repository
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

# Create deployment config directory (this will be your main git repository)
mkdir -p deployment-config
```

### Step 2: Set Up Frappe Docker (Official Repository)

```bash
# Clone the OFFICIAL frappe_docker repository (don't fork it)
cd ~/projects/my-erpnext-project
git clone https://github.com/frappe/frappe_docker.git frappe_docker/
cd frappe_docker

# Set up dev container configuration
cp -R devcontainer-example .devcontainer
cp -R development/vscode-example development/.vscode

# Note: development/frappe-bench will be created when we run 'bench init'
# Don't create it manually as it causes conflicts

# Keep this as the official repo so you can pull updates:
# git pull origin main  # (when Frappe releases updates)
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

# Create your development site (try this first)
bench new-site --no-mariadb-socket development.localhost
# Enter password: 123 (mariadb root password)

# If you get database errors, try this troubleshooting sequence:
# 1. Drop the site and database
# bench drop-site development.localhost --force
# 2. Connect to MariaDB and drop the database manually
# mysql -h mariadb -u root -p123 -e "DROP DATABASE IF EXISTS \`development.localhost\`;"
# 3. Recreate the site
# bench new-site --no-mariadb-socket development.localhost

# Enable developer mode
bench --site development.localhost set-config developer_mode 1
bench --site development.localhost clear-cache

# Install ERPNext
bench get-app --branch version-14 erpnext
bench --site development.localhost install-app erpnext
```

### Step 6: Understanding Git Repository Structure

**Important**: You'll be working with multiple git repositories. Here's how they relate:

### Repository Structure:
```
~/projects/my-erpnext-project/
├── frappe_docker/                    # ✅ Official Frappe repo (don't modify)
│   └── development/                  # Mounted into container
│       └── frappe-bench/             # Created by 'bench init'
│           └── apps/
│               ├── frappe/           # Official Frappe (from bench get-app)
│               ├── erpnext/          # Official ERPNext (from bench get-app)
│               └── my_custom_app/    # ✅ YOUR app with its own git repo
└── deployment-config/               # ✅ Your deployment configuration repo
    ├── .github/workflows/
    ├── iac/
    └── .git/
```

#### Git Repository #1: Your Custom App
- **Location**: Inside the dev container at `/workspace/development/frappe-bench/apps/my_custom_app/`
- **On host**: `~/projects/my-erpnext-project/frappe_docker/development/frappe-bench/apps/my_custom_app/`
- **Purpose**: Contains ONLY your custom Frappe/ERPNext application code
- **Repository**: `https://github.com/your-username/my-custom-app.git`
- **Important**: This directory is MOUNTED, so git operations work from inside the container

#### Git Repository #2: Your Deployment Configuration  
- **Location**: `~/projects/my-erpnext-project/deployment-config/`
- **Purpose**: Contains infrastructure code, workflows, and deployment configuration
- **Repository**: `https://github.com/your-username/my-erpnext-deployment.git`

#### NOT a Git Repository: frappe_docker
- **Location**: `~/projects/my-erpnext-project/frappe_docker/`
- **Purpose**: Official Frappe Docker setup - keep it clean, pull updates from Frappe
- **Don't**: Make it your own repository or modify the core files

### Step 7: Create Your Custom App and Set Up Git

```bash
# Still inside dev container
cd /workspace/development/frappe-bench

# Create a new custom app
bench new-app my_custom_app
# Follow the prompts for app details

# Install the app on your site
bench --site development.localhost install-app my_custom_app

# Set up git repository for your custom app (this happens INSIDE the dev container)
cd apps/my_custom_app

# Configure git inside the container
git config --global user.email "your-email@example.com"
git config --global user.name "Your Name"

# Initialize git repository for YOUR custom app only
git init
git add .
git commit -m "Initial custom app setup"

# Create a NEW repository on GitHub first: https://github.com/your-username/my-custom-app
# Then connect it (this pushes from inside the container to GitHub):
git remote add origin https://github.com/your-username/my-custom-app.git
git push -u origin main
```

### Step 8: Set Up Your Deployment Configuration Repository

```bash
# Exit the dev container (close VS Code dev container mode)
# Open a regular terminal on your host machine

cd ~/projects/my-erpnext-project/deployment-config

# Initialize as git repository
git init
git add .
git commit -m "Initial deployment configuration"

# Create a NEW repository on GitHub: https://github.com/your-username/my-erpnext-deployment
# Then connect it:
git remote add origin https://github.com/your-username/my-erpnext-deployment.git
git push -u origin main
```

### Step 9: Daily Development Workflow

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
# Examples:
# - Add new DocTypes in my_custom_app/my_custom_app/doctype/
# - Create custom scripts in my_custom_app/my_custom_app/public/js/
# - Add custom reports, etc.

# Commit changes to your CUSTOM APP repository (from inside the dev container):
cd /workspace/development/frappe-bench/apps/my_custom_app
git add .
git commit -m "Add new feature"
git push  # This pushes from container to GitHub

# Note: Because development/ is mounted, this git repository persists
# You're working inside the container but the .git folder is on your host machine
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

You can deploy the Terraform backend using the provided script or manually with Terraform commands. Note that the script encapsulates the same Terraform commands, so running both options in the same directory would duplicate the deployment.

#### Option 1: Using the Script

```bash
# Deploy the Terraform backend
./scripts/deploy-backend.sh

# This creates:
# - S3 bucket for Terraform state
# - DynamoDB table for state locking
# - IAM policies for access
```

#### Option 2: Manual Deployment

Navigate to the `bootstrap` directory before running the commands:

```bash
# Change to bootstrap directory
cd bootstrap

# Initialize Terraform
terraform init
terraform validate
terraform plan
terraform apply

# Follow the prompts to confirm the deployment.
```

### Step 3: Deploy Main Infrastructure

You can deploy the main infrastructure using the provided script or manually with Terraform commands. Note that the script encapsulates the same Terraform commands, so running both options in the same directory would duplicate the deployment.

#### Option 1: Using the Script

```bash
# Deploy the main infrastructure
./scripts/deploy-main.sh

# This creates:
# - VPC and networking components
# - EC2 instance with security group
# - S3 bucket for backups
# - IAM roles and policies
```

#### Option 2: Manual Deployment

Navigate to the main Terraform directory before running the commands:

```bash
# Change to main Terraform directory
cd iac/aws/ec2/terraform

# Initialize Terraform
terraform init
terraform validate
terraform plan
terraform apply

# Follow the prompts to confirm the deployment.
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

### Step 1: Verify Your Deployment Repository

```bash
# Make sure you're in your deployment configuration repository
cd ~/projects/my-erpnext-project/deployment-config

# Verify the structure
ls -la
# Should show: .github/, iac/, .git/, README.md

# Check git status
git status
# Should show it's a clean git repository
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

## Understanding the Two-Repository Workflow

**Key Insight**: You work with the **official frappe_docker repository** but create **your own custom app repository** inside it.

### Repository 1: Your Custom App Repository (Inside Dev Container)
- **What**: ONLY your custom Frappe/ERPNext application code
- **Where**: Lives inside the mounted `development/` directory
- **How it works**: 
  - You develop inside the dev container
  - The directory is mounted, so git operations from inside the container affect the host
  - You commit and push from inside the container to your GitHub repository
- **When to commit**: When you add features, fix bugs, or make changes to your custom app
- **Example**: 
  ```bash
  # Inside dev container:
  cd /workspace/development/frappe-bench/apps/my_custom_app
  git add .
  git commit -m "Add new Customer Portal feature"
  git push  # Goes to YOUR GitHub repo
  ```

### Repository 2: Deployment Configuration Repository (On Host)
- **What**: Infrastructure code, GitHub Actions workflows, deployment configuration  
- **Where**: `~/projects/my-erpnext-project/deployment-config/`
- **How it works**: Regular git repository on your host machine
- **When to commit**: When you change infrastructure, workflows, or deployment settings
- **Example**:
  ```bash
  # On host machine:
  cd ~/projects/my-erpnext-project/deployment-config
  git add .
  git commit -m "Update SSL certificate configuration"
  git push  # Goes to your deployment config GitHub repo
  ```

### NOT Your Repository: frappe_docker (Official)
- **What**: Official Frappe Docker setup and configuration
- **Where**: `~/projects/my-erpnext-project/frappe_docker/`
- **Purpose**: Keep this as the official Frappe repository
- **Why**: So you can pull updates when Frappe releases new versions
- **Example**:
  ```bash
  # Occasionally update to latest Frappe Docker:
  cd ~/projects/my-erpnext-project/frappe_docker
  git pull origin main
  ```

### The Magic: Mounted Directories

The key to understanding this is that the `development/` directory is **mounted** into the container:

```
Host Machine Path:
~/projects/my-erpnext-project/frappe_docker/development/frappe-bench/apps/my_custom_app/
                    ↕ (mounted as)
Container Path:  
/workspace/development/frappe-bench/apps/my_custom_app/
```

So when you work inside the container at `/workspace/development/...`, you're actually working with files on your host machine. That's why git repositories work from inside the container!
