# xpress
An easy way to deliver the Frappe Framework to common IaaS, PaaS, and local systems.

## Quick Start

Choose your path to get started with Frappe/ERPNext development and deployment:

### 🚀 For Developers: Complete Dev-to-Deploy Workflow
```bash
# 1. Set up development environment
cd deploy/
./dev_mmp_stack.sh init my-project --with-mmp
code ../development/my-project/frappe_docker/

# 2. In VSCode: "Dev Containers: Reopen in Container", then:
cd development && ./setup-bench.sh

# 3. Develop your custom apps, then build production image
./build_mmp_stack.sh build --app github.com/user/my-app:main --push

# 4. Deploy and test
./deploy_mmp_local.sh deploy --ssl
```

### 🏗️ For DevOps: Docker Images & Deployment
```bash
# Build and deploy standard ERPNext stack
cd deploy/
./build_mmp_stack.sh build --push
./deploy_mmp_local.sh deploy --ssl

# Access: https://mmp.local (credentials via ./deploy_mmp_local.sh show-secrets mmp-local)
```

### ☁️ For Production: Infrastructure as Code
```bash
# Deploy to AWS EC2 with Terraform
cd iac/aws/ec2/terraform/
./deploy-backend.sh
```

---

## Overview

xpress is a set of tooling to deliver, setup, and maintain infrastructure and configuration for hosting [Frappe Framework](https://frappeframework.com/) based applications (like [ERPNext](https://erpnext.com/)).

**Key Features:**
- **Development setup:** VSCode dev containers with automated bench setup
- **Docker image building:** Flexible builds with smart defaults  
- **Local deployment:** One-command deployment with SSL support
- **Production infrastructure:** AWS EC2 deployment with Terraform
- **End-to-end workflow:** Development → Build → Deploy pipeline

## Repository Structure

```
xpress/
├── deploy/                     # Build and deployment scripts
│   ├── dev_mmp_stack.sh        # Development environment setup
│   ├── build_mmp_stack.sh      # Docker image building script
│   ├── deploy_mmp_local.sh     # Main deployment script
│   ├── setup-bench-template.sh # Automated bench setup template
│   ├── ssl-options/            # SSL/HTTPS configuration files
│   └── README.md               # Deployment documentation
├── docs/                       # Documentation and requirements
├── iac/                        # Infrastructure as Code
│   └── aws/                    # Amazon Web Services (EC2 ready)
└── README.md                   # This file
```

# Development

## VSCode Development Environment

We've streamlined the VSCode dev container setup to be dead simple. One command gets you a fully configured development environment with automated bench setup:

```bash
# Create environment with automated setup script
cd deploy/
./dev_mmp_stack.sh init my-project --with-mmp
code ../development/my-project/frappe_docker/

# In VSCode: "Dev Containers: Reopen in Container" 
# (Explorer will be empty initially - this is normal!)
# Then run in terminal:
cd development && ./setup-bench.sh
```

This gives you the proven VSCode workflow with zero configuration hassle and one-command bench setup.

### Development Environment Options

```bash
# Standard development setup
./dev_mmp_stack.sh init my-project                    # Frappe + ERPNext

# MMP development  
./dev_mmp_stack.sh init mmp-dev --with-mmp             # Include MMP Core

# Custom configuration
./dev_mmp_stack.sh init client-app --site-name client.localhost --frappe-version version-14

# Frappe only (no ERPNext)
./dev_mmp_stack.sh init frappe-only --no-erpnext
```

### Development Workflow Benefits

- **Automated setup**: Custom `setup-bench.sh` script for one-command bench initialization
- **Configuration-aware**: Setup script customized based on your choices (ERPNext, MMP Core, site name)
- **VSCode-first**: Proven workflow with dev containers
- **Git-centric**: Custom apps pushed to GitHub, then included in builds
- **Environment isolation**: Dev environments in `../development/` to keep repo clean
- **Flexible**: Automated script for speed, manual instructions for learning

## Prerequisites

Before you begin, ensure you have the following installed and configured:

- **Docker** and **docker-compose**
- **VSCode** with [Dev Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)
- **User added to Docker group**
- **Memory allocation**: Allocate at least 4GB of RAM to Docker.
    - [Windows instructions](https://docs.docker.com/docker-for-windows/#resources)
    - [macOS instructions](https://docs.docker.com/desktop/settings/mac/#advanced)

## Manual Development Setup

If you prefer the traditional manual approach or want to understand the process:

<details>
<summary>Click to expand manual setup instructions</summary>

### Setting Up Frappe Development Containers

1. **Clone and navigate to the Frappe Docker repository**:
   ```shell
   git clone https://github.com/frappe/frappe_docker.git
   cd frappe_docker
   ```

2. **Configure development container**:
   - Copy the example devcontainer config:
     ```shell
     cp -R devcontainer-example .devcontainer
     ```
   - Copy VSCode config for debugging:
     ```shell
     cp -R development/vscode-example development/.vscode
     ```

### Using VSCode Remote Containers

1. **Set up the database**:
   - By default, MariaDB is used. To switch to PostgreSQL, edit `.devcontainer/docker-compose.yml` to uncomment the `postgresql` service and comment out `mariadb`.

2. **Open Frappe Docker folder in a container**:
   - In VSCode, run: `Dev Containers: Reopen in Container` from Command Palette (Ctrl+Shift+P).

### Initial Bench Setup

Run these commands in the container terminal. Make sure the user is **frappe**.

1. **Initialize the bench**:
   ```shell
   bench init --skip-redis-config-generation --frappe-branch version-15 frappe-bench
   cd frappe-bench
   ```

2. **Set up hosts**:
   ```shell
   bench set-config -g db_host mariadb
   bench set-config -g redis_cache redis://redis-cache:6379
   bench set-config -g redis_queue redis://redis-queue:6379
   bench set-config -g redis_socketio redis://redis-queue:6379
   ```

3. **Edit Procfile for Redis containers**:
   ```shell
   sed -i '/redis/d' ./Procfile
   ```

### Creating a New Site

1. **Create the site**:
   ```shell
   bench new-site --no-mariadb-socket development.localhost
   ```

2. **Enable Developer Mode**:
   ```shell
   bench --site development.localhost set-config developer_mode 1
   bench --site development.localhost clear-cache
   ```

### Installing Apps

1. **Fetch and install apps**:
   ```shell
   bench get-app --branch version-15 erpnext 
   bench --site development.localhost install-app erpnext
   ```

### Starting Frappe

1. **Run Frappe**:
   ```shell
   bench start
   ```
   - Access Frappe at [http://development.localhost:8000](http://development.localhost:8000)
   - Login with user `Administrator` and the password set during site creation.

</details>

# Docker Image Building

Xpress provides a flexible Docker image building script that simplifies creating custom Frappe stacks. It features smart defaults with full flexibility when needed.

## Quick Start

```bash
# Standard build (Frappe + ERPNext)
cd deploy/
./build_mmp_stack.sh build

# Build and push to registry
./build_mmp_stack.sh build --push

# Build with SSL deployment
./build_mmp_stack.sh build --push
./deploy_mmp_local.sh deploy --ssl
```

## Build Options

**Smart Defaults:**
- **Default**: Frappe + ERPNext (what most developers need)
- **MMP developers**: Add `--mmp` flag for MMP Core integration
- **Base only**: Use `--base-only` for Frappe framework only

**Examples:**
```bash
# Standard builds
./build_mmp_stack.sh build                    # Frappe + ERPNext
./build_mmp_stack.sh build --tag stable --push

# MMP developers
./build_mmp_stack.sh build --mmp              # Adds MMP Core
./build_mmp_stack.sh build --mmp --tag production --push

# Custom apps
./build_mmp_stack.sh build --app github.com/user/hrms:v15 --tag hrms-stack
./build_mmp_stack.sh build --app user/app1:main --app user/app2:develop

# Advanced usage
./build_mmp_stack.sh build --config ./custom-apps.json --tag client-stack
./build_mmp_stack.sh build --registry ghcr.io/username --push
```

**Features:**
- Smart defaults without over-engineering
- Flexible app configuration via command line or JSON files
- Automatic image naming based on content
- Support for multiple registries (Docker Hub, GitHub Container Registry)
- CI/CD ready with consistent command interface

**[See full documentation](deploy/README.md)**

# Deployment

## Local Development Deployment

The fastest way to get ERPNext running locally with improved password handling and SSL support:

```bash
# Quick start - deploys ERPNext v15 with HTTPS
cd deploy/
./deploy_mmp_local.sh deploy --ssl

# Access at https://mmp.local
# View credentials: ./deploy_mmp_local.sh show-secrets mmp-local
```

**Deploy with Custom Images:**
```bash
# Build and deploy in one workflow
./build_mmp_stack.sh build --mmp --push
./deploy_mmp_local.sh deploy mmp-custom mmp.local admin@mmp.local devburner/mmp-erpnext latest --ssl
```

**Features:**
- Improved password handling (no terminal exposure)
- SSL/HTTPS support with Traefik reverse proxy
- Automatic Docker and /etc/hosts setup
- Grafana integration for monitoring
- Complete lifecycle management
- Built on official Frappe easy-install.py
- Integration with custom Docker image builds

**[See full documentation](deploy/README.md)**

## Production Infrastructure

### AWS EC2 - Staging Environment
A cost-effective, single-instance deployment perfect for development and small-scale production.

**Quick Start**:
```bash
cd iac/aws/ec2/terraform/
./deploy-backend.sh
```

**Features**:
- Single EC2 instance with Docker Compose
- Automated SSL certificates with Let's Encrypt
- S3 backups with lifecycle policies
- Systems Manager access (no SSH required)
- Cost: < $20/month

**Documentation**: [AWS EC2 Guide](iac/aws/ec2/terraform/README.md)

### Additional Deployments (Planned)
- **AWS ECS**: Production-ready containers with managed services
- **AWS EKS**: Enterprise Kubernetes with advanced features
- **Azure VM**: Alternative single-instance deployment
- **GCP Compute**: Google Cloud single-instance deployment

[View all deployment options](iac/README.md)

## Manual Install (Alternative)

To manually install frappe/erpnext, you can follow the [official Frappe documentation](https://github.com/frappe/bench/blob/develop/docs/installation.md#manual-install). 

**Prerequisites:**
- Python 3.6+, Node.js 12, Redis 5, MariaDB 10.3/Postgres 9.5
- yarn 1.12+, pip 15+, cron, wkhtmltopdf, Nginx (for production)

**Install Bench:**
```bash
pip3 install frappe-bench
```

## Contributing

Contributing to this project is easy and straightforward:

1. Fork the repository to your own GitHub account.
2. Clone the forked repository to your local machine.
3. Create a new branch for your changes.
4. Make the necessary modifications and improvements.
5. Commit your changes with descriptive commit messages.
6. Push the changes to your forked repository.
7. Submit a pull request from your branch to the main repository.
8. The maintainers will review your pull request and provide feedback if needed.
9. Once your changes are approved, they will be merged into the main codebase.

## System Requirements

The current minimum system requirements/packages can be found in [Frappe's documentation](https://github.com/frappe/bench/blob/develop/docs/installation.md#manual-install).