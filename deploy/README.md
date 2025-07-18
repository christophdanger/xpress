# MMP Local Deployment

Deploy ERPNext locally on Ubuntu with the MMP Core app using Docker.

## Quick Start

```bash
# Deploy with defaults (v15 stable)
./deploy_mmp_local.sh deploy

# Deploy ERPNext 15 (stable)
./deploy_mmp_local.sh deploy mmp-v15 mmp.local admin@mmp.local frappe/erpnext v15

# Deploy ERPNext 14 (stable) 
./deploy_mmp_local.sh deploy mmp-v14 mmp.local admin@mmp.local frappe/erpnext v14

# With custom MMP image
./deploy_mmp_local.sh deploy mmp-prod prod.local admin@prod.local devburner/mmp-erpnext latest
```

**Access:** `http://mmp.local:8080` (or your sitename)  
**Admin Password:** Check `~/mmp-local.env` file

## Commands

```bash
# Deploy new instance
./deploy_mmp_local.sh deploy [project] [sitename] [email] [image] [tag]

# Check status
./deploy_mmp_local.sh status [project]

# View logs
./deploy_mmp_local.sh logs [project] [service]

# Restart services
./deploy_mmp_local.sh restart [project]

# Complete cleanup
./deploy_mmp_local.sh cleanup [project]

# Docker cleanup
./deploy_mmp_local.sh docker-cleanup
```

## What It Does

- Installs Docker if needed and sets up permissions
- Downloads and runs official Frappe easy-install.py
- Automatically adds `.local` domains to `/etc/hosts`
- Creates full ERPNext stack with all services
- Provides simple management commands

## Configuration Options

**Default Setup:**
- Project: `mmp-local`
- Site: `mmp.local` 
- Email: `admin@mmp.local`
- Image: `frappe/erpnext:v15` (stable)
- Port: 8080

**Version Options:**
- `frappe/erpnext:latest` - v16.0.0-dev (development/cutting edge)
- `frappe/erpnext:v15` - ERPNext 15 (stable, recommended)  
- `frappe/erpnext:v14` - ERPNext 14 (stable)
- `frappe/erpnext:v15.70.2` - Specific patch version

**Custom Images:**
- `devburner/mmp-erpnext:latest` - Production MMP image
- `frappe/frappe:latest` - Base Frappe only

## Troubleshooting

**Docker permissions:** Logout/login if you get permission errors  
**Site not accessible:** Check `/etc/hosts` has your sitename  
**Container issues:** Use `docker ps` and `docker logs <container>`

## Files

- `deploy_mmp_local.sh` - Main deployment script
- `mmp-ec2.yaml` - Production EC2 deployment config  
- `production-deployment-guide.md` - Manual deployment guide
- `archive/` - Previous script versions (reference only)

## Based On

Production deployment at `mmp.devburner.io` using official Frappe easy-install script with additional local development conveniences.