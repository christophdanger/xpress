# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Xpress is a deployment toolchain for Frappe Framework applications (like ERPNext) across local, staging, and production environments. It provides simple yet robust deployment scripts, SSL/HTTPS support, and infrastructure-as-code for AWS deployments.

## Key Architecture Components

### Deployment Scripts (`deploy/`)
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

### Local Development Deployment
```bash
# HTTP deployment (simple)
cd deploy/
./deploy_mmp_local.sh deploy

# HTTPS deployment (production-like)
./deploy_mmp_local.sh deploy --ssl

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

### Custom App Integration
- Builds custom Docker images with MMP Core app
- Uses `apps.json` configuration for multi-app builds
- Supports branch-specific builds for development and production

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

## Important Notes

- Always run commands from the appropriate directory (`deploy/` or `iac/aws/ec2/terraform/`)
- SSL deployment automatically updates connection info files with HTTPS URLs
- The `frappe_docker` directory is downloaded during deployment and gitignored
- Terraform state is stored remotely in S3 with proper backend configuration
- Use `--ssl` flag for production-like HTTPS deployment with Traefik reverse proxy