# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Xpress is a deployment toolchain for Frappe Framework applications (like ERPNext) across local, staging, and production environments. It provides simple yet robust deployment scripts, SSL/HTTPS support, and infrastructure-as-code for AWS deployments.

## Key Architecture Components

### Build and Deployment Scripts (`deploy/`)
- **Docker build script**: `build_mmp_stack.sh` - Flexible Docker image building with smart defaults
- **Main deployment script**: `deploy_mmp_local.sh` - Comprehensive local deployment with SSL support
- **SSL integration**: Uses Traefik reverse proxy with self-signed certificates for local HTTPS
- **Service management**: Supports ERPNext, Grafana monitoring, and complete lifecycle management
- **Security**: Passwords stored in user home directory with proper permissions, never in repo

### Infrastructure as Code (`iac/`)
- **AWS EC2 Terraform**: Production-ready single-instance deployment with remote state backend
- **Modular structure**: Separate networking, compute, and bootstrap configurations
- **State management**: S3 backend with proper versioning and encryption

### SSL/HTTPS Architecture
- **Local SSL**: Self-signed certificates stored in user home (`~/project-ssl-certs/`)
- **Traefik integration**: Reverse proxy handles SSL termination and routing
- **Multi-service support**: Main app, Grafana dashboard, and Traefik admin interface
- **Port management**: Traefik dashboard on 8081 to avoid conflicts with frontend on 8080

## Common Commands

### Docker Image Building
```bash
# Standard builds (most common)
cd deploy/
./build_mmp_stack.sh build                    # Frappe + ERPNext (default)
./build_mmp_stack.sh build --push             # Build and push to registry
./build_mmp_stack.sh build --tag stable --push

# MMP developers
./build_mmp_stack.sh build --mmp              # Frappe + ERPNext + MMP Core
./build_mmp_stack.sh build --mmp --tag production --push

# Custom apps
./build_mmp_stack.sh build --app github.com/user/hrms:v15 --tag hrms-stack
./build_mmp_stack.sh build --base-only --tag frappe-only

# Advanced usage
./build_mmp_stack.sh build --config ./my-apps.json --tag client-stack
./build_mmp_stack.sh build --registry ghcr.io/username --push
```

### Local Development Deployment
```bash
# HTTP deployment (simple)
cd deploy/
./deploy_mmp_local.sh deploy

# HTTPS deployment (production-like)
./deploy_mmp_local.sh deploy --ssl

# Deploy with custom image
./deploy_mmp_local.sh deploy custom-stack custom.local admin@custom.local my-registry/my-image latest --ssl

# Add monitoring
./deploy_mmp_local.sh add-grafana mmp-local

# View credentials securely
./deploy_mmp_local.sh show-secrets mmp-local

# Complete cleanup
./deploy_mmp_local.sh cleanup mmp-local
```

### Infrastructure Deployment
```bash
# Bootstrap remote state (one-time)
cd iac/aws/ec2/terraform/bootstrap/
./deploy-bootstrap.sh

# Deploy main infrastructure
cd ../
./deploy-backend.sh
```

### SSL Certificate Management
- Certificates automatically generated in `~/project-ssl-certs/`
- Traefik configuration uses `ssl-options/traefik-dynamic.yaml`
- Cleanup removes certificates from user home directory

## Development Setup

### Frappe Development Environment
The project supports VSCode Dev Containers for Frappe development:
- Uses `frappe_docker` repository (gitignored in deploy/)
- Dev container setup with MariaDB/PostgreSQL options
- Bench-based development workflow with hot reloading

### Docker Image Building
- **Smart defaults**: Frappe + ERPNext by default (no MMP Core unless requested)
- **Flexible configuration**: Support for custom apps, multiple registries, and config files
- **Auto image naming**: `frappe-erpnext`, `mmp-erpnext`, `frappe-base` based on content
- **End-to-end workflow**: Build → Push → Deploy in simple commands

### Custom App Integration
- Dynamic `apps.json` generation based on command line flags
- Support for GitHub shorthand (`user/repo:branch`) and full URLs
- Branch-specific builds for development and production
- Configuration file support for complex multi-app setups

## File Structure Patterns

### Deployment Files Location
- Runtime files (compose, secrets, certificates) stored in user home directory
- Example: `~/mmp-local-compose.yml`, `~/mmp-local-secrets.txt`, `~/mmp-local-ssl-certs/`
- This keeps the repository clean and avoids accidental commits of sensitive data

### SSL Files Management
- SSL certificates in user home directory, NOT in repository
- Traefik configuration files in `ssl-options/` (tracked in git)
- Self-signed certificates with 365-day validity

### Docker Integration
- Uses official Frappe easy-install.py for deployment
- Custom image builds via frappe_docker's layered approach
- Traefik v2.11 for SSL termination and routing

## Security Considerations

- All sensitive files (passwords, certificates) stored in user home with proper permissions
- SSL certificates gitignored to prevent accidental commits
- Deployment secrets accessible only via `show-secrets` command
- No hardcoded credentials in any configuration files

## Testing Commands

### Local Testing
```bash
# Test HTTP deployment
curl -H "Host: mmp.local" http://localhost:8080/

# Test HTTPS deployment (with SSL)
curl -k -H "Host: mmp.local" https://localhost/
curl -k -H "Host: grafana.mmp.local" https://localhost/
```

### EC2 Remote Testing
```bash
# Replace YOUR_EC2_IP with actual EC2 instance IP
curl -k -H "Host: mmp.local" https://YOUR_EC2_IP/
curl -k -H "Host: grafana.mmp.local" https://YOUR_EC2_IP/
```

## Build and Deploy Workflows

### Standard Developer Workflow
```bash
# 1. One-time setup
cd deploy/
./build_mmp_stack.sh setup

# 2. Build and deploy standard stack
./build_mmp_stack.sh build --push
./deploy_mmp_local.sh deploy --ssl

# 3. Add monitoring
./deploy_mmp_local.sh add-grafana mmp-local
```

### MMP Developer Workflow
```bash
# 1. Build MMP stack
./build_mmp_stack.sh build --mmp --tag develop --push

# 2. Deploy with MMP image
./deploy_mmp_local.sh deploy mmp-dev mmp.local admin@mmp.local devburner/mmp-erpnext develop --ssl

# 3. Test and iterate
./deploy_mmp_local.sh show-secrets mmp-dev
```

### Custom App Development
```bash
# 1. Build with custom app
./build_mmp_stack.sh build --app github.com/user/hrms:v15 --tag hrms-stack --push

# 2. Deploy custom stack
./deploy_mmp_local.sh deploy hrms-test hrms.local admin@hrms.local devburner/frappe-erpnext hrms-stack --ssl

# 3. Verify deployment
./deploy_mmp_local.sh status hrms-test
```

### Multi-App Enterprise Setup
```bash
# 1. Create apps configuration
cat > custom-apps.json << EOF
[
  {
    "url": "https://github.com/frappe/erpnext.git",
    "branch": "version-15"
  },
  {
    "url": "https://github.com/user/hrms.git",
    "branch": "v15"
  },
  {
    "url": "https://github.com/user/accounting.git",
    "branch": "main"
  }
]
EOF

# 2. Build with config file
./build_mmp_stack.sh build --config custom-apps.json --tag enterprise-v1 --push

# 3. Deploy enterprise stack
./deploy_mmp_local.sh deploy enterprise enterprise.local admin@enterprise.local devburner/frappe-erpnext enterprise-v1 --ssl
```

## Important Notes

- Always run commands from the appropriate directory (`deploy/` or `iac/aws/ec2/terraform/`)
- Build script auto-downloads `frappe_docker` repository (gitignored)
- SSL deployment automatically updates connection info files with HTTPS URLs
- Terraform state is stored remotely in S3 with proper backend configuration
- Use `--ssl` flag for production-like HTTPS deployment with Traefik reverse proxy
- Default builds include Frappe + ERPNext only (no MMP Core unless `--mmp` flag used)
- Image naming automatically adjusts based on apps included in build