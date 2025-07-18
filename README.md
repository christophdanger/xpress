# xpress
An easy way to deliver the Frappe Framework to common IaaS, PaaS, and local systems.

## Overview

xpress is a set of tooling to deliver, setup, and maintain infrastructure and configuration for hosting [Frappe Framework](https://frappeframework.com/) based applications (like [ERPNext](https://erpnext.com/)).

**Quick paths to get started:**
- **Local development:** [Development setup](#getting-started-with-frappe-development) with VSCode containers
- **Docker image building:** [Custom image builds](#docker-image-building) with `./build_mmp_stack.sh build`
- **Local deployment:** [One-command deployment](#local-development-deployment) with `./deploy_mmp_local.sh deploy`
- **Production infrastructure:** [AWS EC2 deployment](#aws-ec2---staging-environment) with Terraform

The current minimum system requirements/packages can be found here on [Frappe's docs](https://github.com/frappe/bench/blob/develop/docs/installation.md#manual-install).

## Repository Structure

```
xpress/
├── deploy/                     # Build and deployment scripts
│   ├── build_mmp_stack.sh      # Docker image building script
│   ├── deploy_mmp_local.sh     # Main deployment script
│   ├── ssl-options/            # SSL/HTTPS configuration files
│   ├── production-deployment-guide.md
│   └── README.md               # Deployment documentation
├── docs/                       # Documentation and requirements
│   ├── ai/                     # AI generated, draft content
│   └── aws/                    # AWS-specific documentation
├── iac/                        # Infrastructure as Code
│   ├── aws/                    # Amazon Web Services
│   ├── azure/                  # Microsoft Azure (planned)
│   └── gcp/                    # Google Cloud Platform (planned)
└── README.md                   # This file
```

# Getting Started with Frappe Development

You can follow the detailed guide here [Frappe Docker - Development](https://github.com/frappe/frappe_docker/blob/main/docs/development.md), but the following is a concise version to get up and running with a local development environment using Docker, VS Code, and Dev Containers:

## Prerequisites

Before you begin, ensure you have the following installed and configured:

- **Docker** and **docker-compose**
- **User added to Docker group**
- **Memory allocation**: Allocate at least 4GB of RAM to Docker.
    - [Windows instructions](https://docs.docker.com/docker-for-windows/#resources)
    - [macOS instructions](https://docs.docker.com/desktop/settings/mac/#advanced)

## Setting Up Frappe Development Containers

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

## Using VSCode Remote Containers

Frappe development is best managed with [VSCode Dev Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers).

### Steps

1. **Set up the database**:
   - By default, MariaDB is used. To switch to PostgreSQL, edit `.devcontainer/docker-compose.yml` to uncomment the `postgresql` service and comment out `mariadb`.

2. **Install Dev Containers extension**:
   - Run the command: `code --install-extension ms-vscode-remote.remote-containers` or install from VSCode Extensions (Ctrl+Shift+X on Windows, Cmd+Shift+X on macOS).

3. **Open Frappe Docker folder in a container**:
   - In VSCode, run: `Dev Containers: Reopen in Container` from Command Palette (Ctrl+Shift+P).

> **Note**: The `development` directory is ignored by Git and mounted in the container. Use this for all benches (Frappe installations).

## Initial Bench Setup

Run these commands in the container terminal. Make sure the user is **frappe**.

1. **Initialize the bench**:
   ```shell
   bench init --skip-redis-config-generation --frappe-branch version-14 frappe-bench
   cd frappe-bench
   ```

   > For version 13, use Python 3.9 and Node v14:
   ```shell
   nvm use v14
   PYENV_VERSION=3.9.17 bench init --skip-redis-config-generation --frappe-branch version-13 frappe-bench
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

## Creating a New Site

Run the following commands to create a site:

1. **Create the site**:
   ```shell
   bench new-site --no-mariadb-socket development.localhost
   ```
   > Replace `development.localhost` with your site name. MariaDB root password is `123`.

2. **Use PostgreSQL** (if preferred):
   ```shell
   bench new-site --db-type postgres --db-host postgresql mypgsql.localhost
   ```

3. **Enable Developer Mode**:
   ```shell
   bench --site development.localhost set-config developer_mode 1
   bench --site development.localhost clear-cache
   ```

## Installing Apps

1. **Fetch and install apps**:
   ```shell
   bench get-app --branch version-14 erpnext 
   bench --site development.localhost install-app erpnext
   ```

   > **Note**: Frappe and ERPNext must be on the same version branch (e.g., version-14).

## Starting Frappe

1. **Run Frappe**:
   ```shell
   bench start
   ```
   - Access Frappe at [http://development.localhost:8000](http://development.localhost:8000)
   - Login with user `Administrator` and the password set during site creation.

## Debugging in VSCode

1. **Install Python extension for VSCode**:
   - Open the Extensions tab, search for `ms-python.python`, and install it on the dev container.
   
2. **Start with debugging**:
   - Use the following to start Frappe processes without Redis and web:
     ```shell
     honcho start socketio watch schedule worker_short worker_long
     ```
   - Launch the `web` process from the VSCode debugger tab.

## Interactive Console for Development

1. **Launch Frappe Console**:
   ```shell
   bench --site development.localhost console
   ```
2. **Jupyter integration**:
   - Run the following in a Jupyter cell:
     ```python
     import frappe
     frappe.init(site='development.localhost', sites_path='/workspace/development/frappe-bench/sites')
     frappe.connect()
     frappe.local.lang = frappe.db.get_default('lang')
     frappe.db.connect()
     ```

## Additional Tools

1. **Mailpit for Email Testing**:
   - Uncomment the `mailpit` service in `docker-compose.yml`. Access Mailpit UI at `localhost:8025`.

2. **Cypress UI Tests**:
   - Install X11 tooling and configure the environment for Cypress testing.
   - Refer to [Cypress Documentation](https://www.cypress.io/blog/2019/05/02/run-cypress-with-a-single-docker-command) for more.

## Manual Container Management

To run containers outside VSCode:

1. **Start Containers**:
   ```shell
   docker-compose -f .devcontainer/docker-compose.yml up -d
   ```

2. **Enter Development Container**:
   ```shell
   docker exec -e "TERM=xterm-256color" -w /workspace/development -it devcontainer-frappe-1 bash
   ```

---

This structured guide should streamline your Frappe development setup while preserving essential details.

## Docker Image Building

Xpress provides a flexible Docker image building script that simplifies creating custom Frappe stacks. It features smart defaults with full flexibility when needed.

### Quick Start

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

### Build Options

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

### End-to-End Workflow

```bash
# 1. One-time setup
./build_mmp_stack.sh setup

# 2. Build and deploy
./build_mmp_stack.sh build --push
./deploy_mmp_local.sh deploy --ssl

# 3. Add monitoring
./deploy_mmp_local.sh add-grafana mmp-local

# 4. Test and iterate
./deploy_mmp_local.sh show-secrets mmp-local
```

**Features:**
- Smart defaults without over-engineering
- Flexible app configuration via command line or JSON files
- Automatic image naming based on content
- Support for multiple registries (Docker Hub, GitHub Container Registry)
- CI/CD ready with consistent command interface

**[See full documentation](deploy/README.md)**

## Manual Install (referenced from Frappe's docs)
To manually install frappe/erpnext, you can follow this this wiki for Linux and this wiki for MacOS. It gives an excellent explanation about the stack. You can also follow the steps mentioned below:

1. Install Prerequisites
    * Python 3.6+
    * Node.js 12
    * Redis 5					(caching and realtime updates)
    * MariaDB 10.3 / Postgres 9.5			(to run database driven apps)
    * yarn 1.12+					(js dependency manager)
    * pip 15+					(py dependency manager)
    * cron 						(scheduled jobs)
    * wkhtmltopdf (version 0.12.5 with patched qt) 	(for pdf generation)
• Nginx 					(for production)

2. Install Bench

Install the latest bench using pip:

```
pip3 install frappe-bench
```

## Production Deployment

Xpress provides multiple deployment options from local development to production-ready infrastructure, all designed to be simple yet robust.

### Local Development Deployment

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

### Production Infrastructure

For production environments, choose from these battle-tested options:

## Infrastructure Deployments

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

## Contributing

Contributing to this project is easy and straightforward. Simply follow these steps:

1. Fork the repository to your own GitHub account.
2. Clone the forked repository to your local machine.
3. Create a new branch for your changes.
4. Make the necessary modifications and improvements.
5. Commit your changes with descriptive commit messages.
6. Push the changes to your forked repository.
7. Submit a pull request from your branch to the main repository.
8. The maintainers will review your pull request and provide feedback if needed.
9. Once your changes are approved, they will be merged into the main codebase.
