# MMP Local Deployment Scripts

This directory contains scripts for deploying the ERPNext stack with the MMP Core (Manufacturing Management Platform) app locally on Ubuntu systems.

## Scripts

### `frappe_local_deploy.sh`
**Simplified deployment script** - Recommended for local development

A streamlined script that uses the official Frappe easy-install while providing additional management features:
- **Easy-install integration**: Uses the official Frappe easy-install.py script for core deployment
- **Docker setup**: Handles Docker installation and user group setup
- **Interactive menus**: Guided configuration with contextual help
- **MMP-specific defaults**: Pre-configured for `devburner/mmp-erpnext:latest` image
- **Management features**: Deployment cleanup, Docker cleanup, and verification tools
- **Local development focus**: Optimized for `.local` domains and non-SSL setups

### `setup_frappe_single_server.sh`
**Original production script** - Based on existing MMP production deployment

Production-focused script that replicates the mmp.devburner.io setup with:
- Multi-service architecture (Traefik, MariaDB, Redis)
- SSL/TLS with Let's Encrypt
- Production-grade configuration

## Quick Start

### Interactive Local Deployment
```bash
# Make script executable
chmod +x frappe_local_deploy.sh

# Run interactive deployment
./frappe_local_deploy.sh deploy

# Quick deployment with defaults
./frappe_local_deploy.sh deploy --non-interactive
```

### Key Features

#### 🚀 **Easy Docker Setup**
- Automatically installs Docker if not present
- Handles Docker group membership setup
- Lets easy-install handle the complex Docker configuration

#### 📋 **Interactive Configuration**
- Menu-driven Docker image selection
- Contextual help for each option
- Smart defaults based on production MMP setup

#### 🛠 **MMP-Specific**
- Defaults to `devburner/mmp-erpnext:latest`
- Includes ERPNext and MMP customizations
- Production-like local environment

#### 🧹 **Cleanup Options**
- Remove specific deployments
- Clean up Docker resources
- Complete Docker uninstall

## Usage Examples

### Basic Deployment
```bash
./frappe_local_deploy.sh deploy
```
Runs interactive deployment with menus for all options.

### Non-Interactive Deployment
```bash
./frappe_local_deploy.sh deploy --non-interactive
```
Uses MMP defaults for quick setup.

### Custom Configuration
```bash
./frappe_local_deploy.sh deploy \
  --project my-mmp \
  --site app.local \
  --email admin@company.com \
  --port 3000
```

### Cleanup
```bash
# Remove a specific deployment
./frappe_local_deploy.sh cleanup --project mmp-local

# Clean up all unused Docker resources
./frappe_local_deploy.sh docker-cleanup

# Completely remove Docker
./frappe_local_deploy.sh uninstall
```

## Configuration Options

### Docker Image Selection
1. **devburner/mmp-erpnext:latest** (recommended)
   - Production MMP image
   - Includes ERPNext + MMP customizations
   - Matches mmp.devburner.io setup

2. **frappe/erpnext:latest**
   - Standard ERPNext image
   - No MMP customizations

3. **frappe/frappe:latest**
   - Base Frappe without ERPNext

4. **Custom Image**
   - Specify your own Docker image

### Site Configuration
- **mmp.local**: Matches MMP branding
- **erp.local**: ERP-focused development
- **app.local**: Generic application development
- **localhost**: Simple localhost access

### SSL Configuration
- **No SSL**: Recommended for local development
- **SSL**: For production-like testing with certificates

## Default Configuration

The script uses these defaults for quick local development:
- **Project**: `mmp-local`
- **Site**: `mmp.local`
- **Email**: `admin@mmp.local`
- **Image**: `devburner/mmp-erpnext:latest`
- **SSL**: Disabled
- **Port**: 8080

## Post-Deployment

### Accessing Your Site
- **URL**: `http://mmp.local:8080` (or your configured site/port)
- **Admin Login**: Use the password from `~/mmp-local-passwords.txt`

### Useful Commands
```bash
# View running containers
docker ps

# View logs
docker logs mmp-local-backend-1

# Access backend shell
docker exec -it mmp-local-backend-1 bash

# Check MMP apps
docker exec mmp-local-backend-1 ls -la /home/frappe/frappe-bench/apps/

# Site console
docker exec -it mmp-local-backend-1 bench --site mmp.local console
```

## Troubleshooting

### Docker Group Issues
The script handles Docker group membership setup, but if you encounter permission issues:
```bash
# Refresh your group membership
newgrp docker

# Or log out and back in, then re-run
./frappe_local_deploy.sh deploy

# Alternative: Run easy-install directly
python3 easy-install.py deploy --email=admin@mmp.local --sitename=mmp.local
```

### Container Issues
```bash
# Check container status
docker ps -a

# View specific container logs
docker logs mmp-local-backend-1 --tail 50

# Restart deployment
docker compose -p mmp-local up -d
```

### DNS Issues
For `.local` domains, the script automatically adds entries to `/etc/hosts`. If you can't access your site:
```bash
# Verify /etc/hosts entry
grep mmp.local /etc/hosts

# Manually add if missing
echo "127.0.0.1 mmp.local" | sudo tee -a /etc/hosts
```

## Based on Production Setup

This script is based on the working production deployment at `mmp.devburner.io` and incorporates:
- Production-tested Docker image
- Official Frappe easy-install script for reliability
- Working configuration patterns
- Real-world deployment experience
- Additional management and cleanup features

## Contributing

When updating the script:
1. Test on fresh Ubuntu systems
2. Verify Docker group handling
3. Test both interactive and non-interactive modes
4. Update this README with any new features