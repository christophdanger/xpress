# MMP Local Deployment

Deploy ERPNext locally on Ubuntu with the MMP Core app using Docker.

## Quick Start

```bash
# Deploy with defaults (mmp-local, mmp.local, frappe/erpnext:latest)
./frappe_local_deploy_streamlined.sh deploy

# Custom deployment
./frappe_local_deploy_streamlined.sh deploy my-project my-site.local admin@company.com

# With custom image (for MMP)
./frappe_local_deploy_streamlined.sh deploy mmp-prod prod.local admin@prod.local devburner/mmp-erpnext latest
```

**Access:** `http://mmp.local:8080` (or your sitename)  
**Admin Password:** Check `~/mmp-local.env` file

## Commands

```bash
# Deploy new instance
./frappe_local_deploy_streamlined.sh deploy [project] [sitename] [email] [image] [tag]

# Check status
./frappe_local_deploy_streamlined.sh status [project]

# View logs
./frappe_local_deploy_streamlined.sh logs [project] [service]

# Restart services
./frappe_local_deploy_streamlined.sh restart [project]

# Complete cleanup
./frappe_local_deploy_streamlined.sh cleanup [project]
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
- Image: `frappe/erpnext:latest`
- Port: 8080

**Custom Images:**
- `frappe/erpnext:latest` - Standard ERPNext
- `devburner/mmp-erpnext:latest` - Production MMP image
- `frappe/frappe:latest` - Base Frappe only

## Troubleshooting

**Docker permissions:** Logout/login if you get permission errors  
**Site not accessible:** Check `/etc/hosts` has your sitename  
**Container issues:** Use `docker ps` and `docker logs <container>`

## Files

- `frappe_local_deploy_streamlined.sh` - Main deployment script
- `mmp-ec2.yaml` - Production EC2 deployment config  
- `production-deployment-guide.md` - Manual deployment guide
- `archive/` - Previous script versions (reference only)

## Based On

Production deployment at `mmp.devburner.io` using official Frappe easy-install script with additional local development conveniences.