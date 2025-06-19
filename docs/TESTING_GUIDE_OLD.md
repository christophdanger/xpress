# Complete Testing Guide: GitHub Actions + Terraform EC2 Deployment

This guide provides step-by-step instructions for testing the xpress GitHub Actions workflows with Terraform EC2 deployment using your own frappe_docker repository.

## Prerequisites

Before testing, ensure you have:

### AWS Requirements
- ✅ AWS Account with appropriate permissions
- ✅ AWS CLI configured locally
- ✅ Domain name (for SSL testing)
- ✅ Domain DNS configured to point to your EC2 instance

### GitHub Requirements
- ✅ GitHub repository for your project
- ✅ Fork or copy of frappe_docker repository
- ✅ GitHub Secrets configured

### Local Development Environment
- ✅ Terraform installed
- ✅ Git configured
- ✅ VS Code or preferred editor

## Phase 1: Infrastructure Setup and Testing

### Step 1: Copy and Setup Infrastructure

1. **Create your project repository structure**:
   ```bash
   # Create your project repository
   mkdir your-erpnext-project
   cd your-erpnext-project
   git init
   
   # Copy infrastructure from xpress
   mkdir -p iac/aws/ec2
   cp -r /path/to/xpress/iac/aws/ec2/terraform/ iac/aws/ec2/
   ```

2. **Test Terraform infrastructure locally**:
   ```bash
   cd iac/aws/ec2/terraform
   
   # Initialize and validate
   terraform init
   terraform validate
   terraform plan
   ```

### Step 2: Deploy Infrastructure

1. **Deploy the S3 backend**:
   ```bash
   cd iac/aws/ec2/terraform
   ./scripts/deploy-backend.sh
   ```

2. **Deploy main infrastructure**:
   ```bash
   ./scripts/deploy-main.sh
   ```

3. **Verify deployment**:
   ```bash
   # Check outputs
   terraform output
   
   # Test SSH access via Session Manager
   aws ssm start-session --target $(terraform output -raw instance_id)
   ```

### Step 3: Verify Infrastructure Components

Check that all components are working:

```bash
# List all resources
terraform state list

# Check security groups
aws ec2 describe-security-groups --group-ids $(terraform output -raw security_group_id)

# Check S3 bucket
aws s3 ls $(terraform output -raw s3_bucket_name)

# Test EC2 instance
aws ec2 describe-instances --instance-ids $(terraform output -raw instance_id)
```

## Phase 2: GitHub Actions Workflow Setup

### Step 1: Copy and Customize Workflows

1. **Copy workflow templates**:
   ```bash
   mkdir -p .github/workflows
   
   # Copy all templates (remove .template extension)
   cp /path/to/xpress/templates/github-actions/deploy-erpnext.yml.template .github/workflows/deploy-erpnext.yml
   cp /path/to/xpress/templates/github-actions/ssl-configuration.yml.template .github/workflows/ssl-configuration.yml
   cp /path/to/xpress/templates/github-actions/automated-backups.yml.template .github/workflows/automated-backups.yml
   cp /path/to/xpress/templates/github-actions/infrastructure-monitoring.yml.template .github/workflows/infrastructure-monitoring.yml
   cp /path/to/xpress/templates/github-actions/disaster-recovery.yml.template .github/workflows/disaster-recovery.yml
   ```

2. **Customize deploy-erpnext.yml for your frappe_docker repository**:
   ```yaml
   # Update these sections in deploy-erpnext.yml:
   
   env:
     DOMAIN: your-domain.com                    # Your actual domain
     SITE_NAME: your-site                       # Your ERPNext site name
     FRAPPE_DOCKER_REPO: your-username/frappe_docker  # Your frappe_docker fork
     
   # In the clone step:
   - name: Clone frappe_docker repository
     run: |
       git clone https://github.com/your-username/frappe_docker.git ~/frappe_docker
   ```

3. **Update repository references in all workflows**:
   ```bash
   # Replace placeholder repository references
   sed -i 's/your-username\/your-erpnext-repo/your-actual-username\/your-actual-repo/g' .github/workflows/*.yml
   ```

### Step 2: Configure GitHub Secrets

In your GitHub repository settings → Secrets and variables → Actions, add:

#### Required Secrets
```
AWS_ACCESS_KEY_ID=AKIA...
AWS_SECRET_ACCESS_KEY=...
LETSENCRYPT_EMAIL=your-email@domain.com
DB_PASSWORD=your-strong-database-password
ADMIN_PASSWORD=your-erpnext-admin-password
```

#### Optional Secrets
```
BACKUP_RETENTION_DAYS=30
AWS_REGION=us-east-1
```

### Step 3: Test AWS Permissions

Create a test workflow to verify AWS access:

```yaml
# .github/workflows/test-aws-access.yml
name: Test AWS Access
on: workflow_dispatch

jobs:
  test-aws:
    runs-on: ubuntu-latest
    steps:
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: us-east-1

      - name: Test AWS CLI
        run: |
          aws sts get-caller-identity
          aws ec2 describe-instances --instance-ids $(aws ec2 describe-instances --query 'Reservations[0].Instances[0].InstanceId' --output text)
```

## Phase 3: Testing User Story 2.1 - Automated Deployment

### Step 1: Prepare for Deployment Testing

1. **Verify your frappe_docker repository**:
   ```bash
   # Test locally first
   git clone https://github.com/your-username/frappe_docker.git
   cd frappe_docker
   
   # Ensure all required files exist
   ls compose.yaml overrides/
   ```

2. **Check Terraform outputs are accessible**:
   ```bash
   cd iac/aws/ec2/terraform
   terraform output -json > terraform-outputs.json
   cat terraform-outputs.json
   ```

### Step 2: Run the Deployment Workflow

1. **Manual trigger test**:
   - Go to GitHub Actions in your repository
   - Select "Deploy ERPNext" workflow
   - Click "Run workflow"
   - Monitor the execution

2. **Monitor deployment steps**:
   ```bash
   # Check the workflow progress in GitHub Actions
   # Key steps to verify:
   # ✅ AWS credentials configuration
   # ✅ Terraform outputs retrieval
   # ✅ SSM session connection
   # ✅ frappe_docker clone
   # ✅ Docker Compose configuration
   # ✅ ERPNext site creation
   ```

### Step 3: Verify Deployment Success

1. **Connect to EC2 and check containers**:
   ```bash
   # Via Session Manager
   aws ssm start-session --target YOUR_INSTANCE_ID
   
   # On the EC2 instance:
   sudo docker ps
   sudo docker compose --project-name erpnext ps
   ```

2. **Check ERPNext accessibility**:
   ```bash
   # Test HTTP access (before SSL)
   curl -I http://YOUR_DOMAIN
   curl -I http://YOUR_EC2_PUBLIC_IP
   ```

3. **Verify site creation**:
   ```bash
   # On EC2 instance
   sudo docker exec -it erpnext-backend-1 bench --site YOUR_SITE_NAME list-apps
   ```

### Step 4: Troubleshoot Common Issues

#### Issue: Terraform outputs not found
```bash
# Debug: Check if terraform state is accessible
cd iac/aws/ec2/terraform
terraform refresh
terraform output
```

#### Issue: Docker containers not starting
```bash
# Debug: Check container logs
sudo docker compose --project-name erpnext logs
sudo docker compose --project-name erpnext logs backend
```

#### Issue: Site creation fails
```bash
# Debug: Check ERPNext logs
sudo docker exec -it erpnext-backend-1 tail -f /home/frappe/frappe-bench/logs/web.log
```

## Phase 4: Testing User Story 2.2 - SSL Configuration

### Step 1: DNS Configuration

1. **Verify DNS pointing to EC2**:
   ```bash
   # Check DNS resolution
   nslookup your-domain.com
   dig your-domain.com
   
   # Should return your EC2 public IP
   ```

2. **Ensure firewall allows HTTPS**:
   ```bash
   # Test port accessibility
   telnet your-domain.com 80
   telnet your-domain.com 443
   ```

### Step 2: Run SSL Configuration Workflow

1. **Manual trigger**:
   - Go to GitHub Actions → "SSL Configuration"
   - Run workflow with your domain
   - Monitor execution

2. **Verify SSL steps**:
   ```bash
   # Key steps to monitor:
   # ✅ DNS validation
   # ✅ Traefik configuration
   # ✅ Let's Encrypt certificate request
   # ✅ HTTPS redirection setup
   ```

### Step 3: Verify SSL Success

1. **Test HTTPS access**:
   ```bash
   # Test SSL certificate
   curl -I https://your-domain.com
   openssl s_client -connect your-domain.com:443 -servername your-domain.com
   ```

2. **Check certificate details**:
   ```bash
   # Verify certificate issuer and expiry
   echo | openssl s_client -connect your-domain.com:443 2>/dev/null | openssl x509 -noout -dates -issuer
   ```

3. **Test ERPNext over HTTPS**:
   ```bash
   # Access ERPNext login page
   curl -L https://your-domain.com
   ```

### Step 4: Troubleshoot SSL Issues

#### Issue: Let's Encrypt rate limit
```bash
# Check rate limits
# Use staging environment first:
# Modify workflow to use --staging flag for testing
```

#### Issue: DNS propagation delay
```bash
# Wait for DNS propagation (up to 24 hours)
# Test from different locations:
dig @8.8.8.8 your-domain.com
dig @1.1.1.1 your-domain.com
```

## Phase 5: End-to-End Testing

### Step 1: Complete Workflow Test

1. **Full deployment sequence**:
   ```bash
   # 1. Deploy infrastructure
   cd iac/aws/ec2/terraform && ./scripts/deploy-main.sh
   
   # 2. Run deployment workflow (GitHub Actions)
   # 3. Configure DNS
   # 4. Run SSL workflow (GitHub Actions)
   # 5. Test final application
   ```

2. **Verify complete functionality**:
   ```bash
   # Test ERPNext login
   curl -c cookies.txt -b cookies.txt -d "cmd=login&usr=Administrator&pwd=YOUR_ADMIN_PASSWORD" https://your-domain.com/api/method/login
   
   # Test ERPNext API
   curl -c cookies.txt -b cookies.txt https://your-domain.com/api/resource/User
   ```

### Step 2: Backup and Monitoring Setup

1. **Test backup workflow**:
   - Run "Automated Backups" workflow manually
   - Verify S3 backup creation
   - Check backup metadata

2. **Test monitoring workflow**:
   - Run "Infrastructure Monitoring" workflow
   - Review system health report
   - Verify SSL monitoring

### Step 3: Documentation and Cleanup

1. **Document your configuration**:
   ```bash
   # Create deployment notes
   echo "Domain: your-domain.com" > deployment-notes.md
   echo "Deployed: $(date)" >> deployment-notes.md
   terraform output >> deployment-notes.md
   ```

2. **Clean up test resources** (if needed):
   ```bash
   # Destroy infrastructure when testing complete
   cd iac/aws/ec2/terraform
   terraform destroy
   ```

## Common Issues and Solutions

### GitHub Actions Issues

#### Workflow Permission Errors
```yaml
# Add to workflow if needed:
permissions:
  contents: read
  actions: read
  id-token: write  # For OIDC if using
```

#### AWS Session Manager Connection Issues
```bash
# Ensure Session Manager plugin is available on GitHub runners
# This is typically pre-installed on github-hosted runners
```

### Terraform Issues

#### State Lock Issues
```bash
# If state is locked
terraform force-unlock LOCK_ID
```

#### Resource Already Exists
```bash
# Import existing resources if needed
terraform import aws_instance.main i-1234567890abcdef0
```

### ERPNext/Docker Issues

#### Port Conflicts
```bash
# Check for port conflicts on EC2
sudo netstat -tlnp | grep :80
sudo netstat -tlnp | grep :443
```

#### Memory Issues
```bash
# Monitor memory usage
free -h
sudo docker stats
```

## Success Criteria

Your testing is successful when:

- ✅ Infrastructure deploys cleanly via Terraform
- ✅ GitHub Actions workflows run without errors
- ✅ ERPNext is accessible over HTTP
- ✅ SSL certificate is properly configured
- ✅ ERPNext is accessible over HTTPS
- ✅ Backup workflow creates S3 backups
- ✅ Monitoring workflow reports system health
- ✅ All tests pass in your specific environment

## Next Steps

After successful testing:

1. **Document environment-specific configurations**
2. **Set up automated backup schedules**
3. **Configure monitoring alerts**
4. **Plan production deployment strategy**
5. **Implement additional security measures**

This completes the comprehensive testing of User Stories 2.1 and 2.2 with your frappe_docker repository integration.

## Understanding Frappe Docker Modes and Image Building

### The Confusion: Development vs Production

frappe_docker has multiple modes that serve different purposes, and this causes significant confusion:

#### 1. **Development Mode** (VS Code Dev Containers)
- **Purpose**: Local development with live code changes
- **Location**: Inside the dev container (`.devcontainer/`)
- **What it does**: Mounts source code, runs bench commands, hot reloading
- **Image**: Uses base development images, doesn't build custom production images
- **Limitation**: ❌ Cannot build production images from inside dev container

#### 2. **Local Production Testing Mode** 
- **Purpose**: Test production-like deployment locally
- **Location**: Outside dev container, in main repository
- **What it does**: Builds custom images with your apps/customizations
- **Image**: Builds production images with your code baked in
- **Use case**: ✅ Build images for staging/production deployment

#### 3. **Production Deployment Mode**
- **Purpose**: Deploy to servers (our GitHub Actions workflows)
- **Location**: Server/CI environment
- **What it does**: Uses pre-built images or builds on-demand
- **Image**: Uses the images built in mode #2

### The Solution: Two-Repository Approach

To properly work with frappe_docker for production deployments, you need:

```
your-project/
├── frappe_docker/                  # Your fork/copy for image building
├── your-custom-app/               # Your Frappe app (if any)
└── deployment-config/             # xpress templates and configs
```

## Phase 0: Setting Up Frappe Docker for Production Image Building

### Step 1: Understanding the Image Building Process

1. **Fork/Clone frappe_docker outside of dev containers**:
   ```bash
   # Do this in your main development environment (NOT in dev container)
   cd ~/projects
   git clone https://github.com/frappe/frappe_docker.git
   cd frappe_docker
   
   # OR fork it first, then clone your fork
   git clone https://github.com/your-username/frappe_docker.git
   cd frappe_docker
   ```

2. **Understand the directory structure**:
   ```
   frappe_docker/
   ├── .devcontainer/              # For development mode (ignore for production)
   ├── compose.yaml                # Production docker-compose
   ├── overrides/                  # Production overrides
   ├── images/                     # Dockerfiles for building custom images
   ├── development/                # Development setup (ignore for production)
   └── README.md
   ```

### Step 2: Choose Your Production Image Strategy

You have three options for production images:

#### Option A: Use Official Pre-built Images (Simplest)
```yaml
# In your docker-compose override or environment
ERPNEXT_IMAGE=frappe/erpnext:latest
FRAPPE_IMAGE=frappe/frappe:latest
```
- ✅ **Pros**: No building required, fastest deployment
- ❌ **Cons**: No customizations, limited control

#### Option B: Build Custom Images with Your Apps (Recommended)
```bash
# Build custom images with your apps
cd frappe_docker
export APPS_JSON='[
  {
    "url": "https://github.com/frappe/erpnext",
    "branch": "version-14"
  },
  {
    "url": "https://github.com/your-username/your-custom-app",
    "branch": "main"
  }
]'

# Build the images
docker build -t your-registry/custom-erpnext:latest \
  --build-arg APPS_JSON="$APPS_JSON" \
  images/custom/
```

#### Option C: Use GitHub Actions to Build Images (Advanced)
Set up automated image building in your frappe_docker fork.

### Step 3: Building Production Images (Option B - Detailed)

1. **Prepare your frappe_docker for custom builds**:
   ```bash
   cd frappe_docker
   
   # Create apps.json for your deployment
   cat > apps.json << EOF
   [
     {
       "url": "https://github.com/frappe/erpnext",
       "branch": "version-14"
     },
     {
       "url": "https://github.com/your-username/your-custom-app",
       "branch": "main"
     }
   ]
   EOF
   ```

2. **Build custom ERPNext image**:
   ```bash
   # Build with your custom apps
   export APPS_JSON_BASE64=$(base64 -w 0 apps.json)
   
   docker build \
     --build-arg APPS_JSON_BASE64=$APPS_JSON_BASE64 \
     --tag your-dockerhub-username/custom-erpnext:v14-latest \
     --file images/custom/Containerfile .
   ```

3. **Test the custom image locally**:
   ```bash
   # Create a test compose file
   cat > docker-compose.test.yml << EOF
   version: "3.7"
   services:
     backend:
       image: your-dockerhub-username/custom-erpnext:v14-latest
       # ... other configuration
   EOF
   
   # Test locally
   docker-compose -f docker-compose.test.yml up
   ```

4. **Push to container registry**:
   ```bash
   # Push to Docker Hub (or your preferred registry)
   docker login
   docker push your-dockerhub-username/custom-erpnext:v14-latest
   ```

### Step 4: Update Your GitHub Actions Workflows

Once you have your custom images, update your deployment workflow:

```yaml
# In .github/workflows/deploy-erpnext.yml
env:
  CUSTOM_ERPNEXT_IMAGE: your-dockerhub-username/custom-erpnext:v14-latest
  CUSTOM_FRAPPE_IMAGE: your-dockerhub-username/custom-frappe:v14-latest

# In the deployment step:
- name: Configure ERPNext with custom images
  run: |
    # Set custom images in environment
    echo "ERPNEXT_IMAGE=${{ env.CUSTOM_ERPNEXT_IMAGE }}" >> ~/gitops/erpnext.env
    echo "FRAPPE_IMAGE=${{ env.CUSTOM_FRAPPE_IMAGE }}" >> ~/gitops/erpnext.env
```

### Step 5: Alternative - Build Images in GitHub Actions

If you want to build images as part of your deployment:

```yaml
# Add this job before deployment in your workflow
build-custom-images:
  runs-on: ubuntu-latest
  steps:
    - name: Checkout frappe_docker
      uses: actions/checkout@v3
      with:
        repository: your-username/frappe_docker
        path: frappe_docker

    - name: Build custom ERPNext image
      run: |
        cd frappe_docker
        export APPS_JSON='[{"url": "https://github.com/frappe/erpnext", "branch": "version-14"}]'
        docker build -t custom-erpnext:latest --build-arg APPS_JSON="$APPS_JSON" images/custom/
        
    - name: Save image as artifact
      run: |
        docker save custom-erpnext:latest | gzip > custom-erpnext.tar.gz
        
    - name: Upload image artifact
      uses: actions/upload-artifact@v3
      with:
        name: custom-erpnext-image
        path: custom-erpnext.tar.gz
```

## Complete Development Workflow: From Code to Production

### The Git Repository Problem in Dev Containers

You've identified the core issue: **frappe_docker dev containers don't have git repositories by default**, and your changes seem to disappear. Here's the complete workflow to solve this:

### Understanding the File Mounting Structure

When you use frappe_docker dev containers:

```
Host Machine:
├── frappe_docker/              # The frappe_docker repository
│   ├── .devcontainer/         # Dev container config  
│   └── development/           # ⚠️ This directory is mounted INTO the container
       └── (empty initially)

Inside Dev Container:
├── /workspace/
│   ├── development/           # Mounted from host
│   └── frappe_docker/         # Read-only frappe_docker files
```

**Key insight**: The `development/` directory is mounted from your host machine, so anything you create there persists.

## Complete Development Workflow

### Phase 1: Initial Setup (One Time)

#### Step 1: Set Up Directory Structure on Host
```bash
# On your host machine (NOT in dev container)
mkdir -p ~/projects/my-erpnext-project
cd ~/projects/my-erpnext-project

# Create the structure
mkdir -p frappe_docker
mkdir -p custom-apps
mkdir -p deployment-config

# Clone frappe_docker
git clone https://github.com/frappe/frappe_docker.git frappe_docker/
cd frappe_docker
```

#### Step 2: Prepare Dev Container for Custom Development
```bash
# Still on host machine, in frappe_docker directory
cp -R devcontainer-example .devcontainer
cp -R development/vscode-example development/.vscode

# Create development directories that will persist
mkdir -p development/frappe-bench
mkdir -p development/custom-apps
```

#### Step 3: Set Up Your Custom App Repository
```bash
# Create your custom app repository (on host)
cd ~/projects/my-erpnext-project/custom-apps
git init my-custom-app
cd my-custom-app

# Create initial app structure
mkdir -p my_custom_app
echo "# My Custom ERPNext App" > README.md
git add .
git commit -m "Initial commit"

# Push to GitHub
git remote add origin https://github.com/your-username/my-custom-app.git
git push -u origin main
```

### Phase 2: Development Workflow

#### Step 1: Enter Dev Container for Development
```bash
# Open frappe_docker in VS Code
cd ~/projects/my-erpnext-project/frappe_docker
code .

# VS Code will detect .devcontainer and ask to reopen in container
# Click "Reopen in Container"
```

#### Step 2: Set Up Bench in Dev Container (First Time)
```bash
# Now you're inside the dev container
# The development/ directory is mounted from your host

cd /workspace/development

# Initialize bench (this creates files in the mounted directory)
bench init --skip-redis-config-generation --frappe-branch version-14 frappe-bench
cd frappe-bench

# Configure for dev containers
bench set-config -g db_host mariadb
bench set-config -g redis_cache redis://redis-cache:6379
bench set-config -g redis_queue redis://redis-queue:6379
bench set-config -g redis_socketio redis://redis-queue:6379

# Remove redis from Procfile (using containers)
sed -i '/redis/d' ./Procfile

# Create new site
bench new-site --no-mariadb-socket development.localhost
# Password: 123 (mariadb root password)

# Enable developer mode
bench --site development.localhost set-config developer_mode 1
bench --site development.localhost clear-cache
```

#### Step 3: Add Your Custom App to Development
```bash
# Still inside dev container, in /workspace/development/frappe-bench

# Get your custom app (method 1: from existing repo)
bench get-app https://github.com/your-username/my-custom-app.git

# OR method 2: create new app
bench new-app my_custom_app

# Install app on site
bench --site development.localhost install-app my_custom_app
```

#### Step 4: Set Up Git Tracking for Your Custom App
```bash
# The key insight: Your app code is in the mounted development/ directory
cd /workspace/development/frappe-bench/apps/my_custom_app

# This directory IS persistent and can have its own git repository
git init
git remote add origin https://github.com/your-username/my-custom-app.git

# Make your changes
# Edit files in my_custom_app/
# Add docTypes, custom scripts, etc.

# Commit changes
git add .
git commit -m "Add custom functionality"
git push origin main
```

### Phase 3: Development Day-to-Day Workflow

#### Daily Development Process:
```bash
# 1. Start development
cd ~/projects/my-erpnext-project/frappe_docker
code .  # Opens in dev container

# 2. Inside dev container - start bench
cd /workspace/development/frappe-bench
bench start

# 3. Access ERPNext at http://development.localhost:8000
# Make your changes to custom apps

# 4. Your changes are in: /workspace/development/frappe-bench/apps/my_custom_app/
# This directory is mounted from host, so changes persist

# 5. Commit changes
cd /workspace/development/frappe-bench/apps/my_custom_app
git add .
git commit -m "Add new feature"
git push
```

#### File Persistence Mapping:
```
Host Machine Path: ~/projects/my-erpnext-project/frappe_docker/development/
    ↕ (mounted as)
Container Path: /workspace/development/

So when you edit files in the container at:
/workspace/development/frappe-bench/apps/my_custom_app/

They actually exist on your host at:
~/projects/my-erpnext-project/frappe_docker/development/frappe-bench/apps/my_custom_app/
```

### Phase 4: Local Production Testing

#### Step 1: Exit Dev Container and Build Production Images
```bash
# Exit VS Code dev container mode
cd ~/projects/my-erpnext-project/frappe_docker

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

# Build custom image with your app
export APPS_JSON_BASE64=$(base64 -w 0 apps.json)
docker build \
  --build-arg APPS_JSON_BASE64=$APPS_JSON_BASE64 \
  --tag my-custom-erpnext:latest \
  --file images/custom/Containerfile .
```

#### Step 2: Test Production Image Locally
```bash
# Create production test environment
cat > docker-compose.production-test.yml << EOF
version: "3.7"

x-customizable-image: &customizable_image my-custom-erpnext:latest

services:
  backend:
    <<: *customizable_image
    deploy:
      replicas: 1
    volumes:
      - sites:/home/frappe/frappe-bench/sites
      - logs:/home/frappe/frappe-bench/logs

  # ... rest of your production config
EOF

# Test with production image
docker-compose -f docker-compose.production-test.yml up
```

### Phase 5: Deployment Workflow

#### Step 1: Prepare for Production Deployment
```bash
# Push your custom app changes
cd ~/projects/my-erpnext-project/frappe_docker/development/frappe-bench/apps/my_custom_app
git push origin main

# Build and push production image
cd ~/projects/my-erpnext-project/frappe_docker
docker build \
  --build-arg APPS_JSON_BASE64=$APPS_JSON_BASE64 \
  --tag your-dockerhub-username/my-custom-erpnext:v1.0.0 \
  --file images/custom/Containerfile .

docker push your-dockerhub-username/my-custom-erpnext:v1.0.0
```

#### Step 2: Update GitHub Actions Workflow
```yaml
# In your deployment repository's .github/workflows/deploy-erpnext.yml
env:
  CUSTOM_ERPNEXT_IMAGE: your-dockerhub-username/my-custom-erpnext:v1.0.0

steps:
  - name: Deploy with custom image
    run: |
      echo "ERPNEXT_IMAGE=${{ env.CUSTOM_ERPNEXT_IMAGE }}" >> ~/gitops/erpnext.env
      # ... rest of deployment
```

## Project Structure Best Practices

### Recommended Directory Structure:
```
~/projects/my-erpnext-project/
├── frappe_docker/                          # frappe_docker repo
│   ├── .devcontainer/                     # Dev container config
│   ├── development/                       # Mounted into container
│   │   └── frappe-bench/                  # Created by bench init
│   │       ├── apps/
│   │       │   ├── frappe/               # Standard frappe
│   │       │   ├── erpnext/              # Standard erpnext
│   │       │   └── my_custom_app/        # ✅ Your app with git repo
│   │       └── sites/
│   ├── images/                           # For building custom images
│   └── compose.yaml                      # Production compose
├── deployment-config/                     # xpress templates
│   ├── .github/workflows/
│   └── iac/
└── README.md                             # Project documentation
```

### Git Repository Structure:
```
Your Custom App Repo (my-custom-app):
├── my_custom_app/
│   ├── __init__.py
│   ├── hooks.py
│   ├── modules.txt
│   └── my_custom_app/
│       ├── doctype/
│       ├── custom/
│       └── public/
├── setup.py
└── README.md

Your Deployment Config Repo:
├── .github/workflows/          # xpress workflows
├── iac/                       # Terraform infrastructure  
└── docker-compose.production.yml
```

## Common Issues and Solutions

### Issue 1: "My changes disappeared when I restart the container"
```bash
# ✅ Solution: Ensure you're working in the mounted directory
cd /workspace/development/frappe-bench/apps/my_custom_app
pwd  # Should show /workspace/development/...

# ❌ Don't work in: /home/frappe/frappe-bench (not mounted)
```

### Issue 2: "Git doesn't work in the dev container"
```bash
# ✅ Solution: Configure git in the dev container
git config --global user.email "you@example.com" 
git config --global user.name "Your Name"

# Or add to .devcontainer/devcontainer.json:
"postCreateCommand": "git config --global user.email 'you@example.com'"
```

### Issue 3: "I can't see my changes in production"
```bash
# ✅ Solution: You need to rebuild and redeploy the image
# 1. Commit changes to your custom app
# 2. Rebuild the custom Docker image
# 3. Push the new image to registry
# 4. Update deployment to use new image tag
```

### Issue 4: "Development and production behave differently"
```bash
# ✅ Solution: Test with production image locally before deploying
docker-compose -f docker-compose.production-test.yml up
```

## Summary: Complete Workflow Checklist

### ✅ One-Time Setup:
1. Create project directory structure
2. Clone frappe_docker
3. Set up dev container
4. Create custom app repository
5. Set up deployment configuration

### ✅ Daily Development:
1. Open frappe_docker in VS Code (dev container mode)
2. Start bench development server
3. Make changes to custom apps
4. Test changes locally
5. Commit and push custom app changes

### ✅ Production Release:
1. Exit dev container mode
2. Build production image with custom apps
3. Test production image locally
4. Push image to registry
5. Deploy via GitHub Actions

This workflow gives you:
- ✅ Persistent development environment
- ✅ Version controlled custom code
- ✅ Local production testing
- ✅ Automated deployment pipeline
- ✅ Clear separation of concerns
