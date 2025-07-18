# MMP Local Deployment

Deploy ERPNext locally on Ubuntu with the MMP Core app using Docker with improved password handling.

## Quick Start

```bash
# Deploy with defaults (HTTP - v15 stable)
./deploy_mmp_local.sh deploy

# Deploy with SSL/HTTPS (production-like)
./deploy_mmp_local.sh deploy --ssl

# Deploy ERPNext 15 (stable)
./deploy_mmp_local.sh deploy mmp-v15 mmp.local admin@mmp.local frappe/erpnext v15

# Deploy ERPNext 14 with SSL
./deploy_mmp_local.sh deploy mmp-v14 mmp.local admin@mmp.local frappe/erpnext v14 --ssl

# With custom MMP image
./deploy_mmp_local.sh deploy mmp-prod prod.local admin@prod.local devburner/mmp-erpnext latest
```

**Access:** 
- HTTP: `http://mmp.local:8080` (or your sitename)
- HTTPS: `https://mmp.local` (with --ssl flag)

**Credentials:** Run `./deploy_mmp_local.sh show-secrets mmp-local` to display passwords

## Commands

```bash
# Deploy new instance
./deploy_mmp_local.sh deploy [project] [sitename] [email] [image] [tag] [--ssl]

# Check status
./deploy_mmp_local.sh status [project]

# View logs
./deploy_mmp_local.sh logs [project] [service]

# Restart services
./deploy_mmp_local.sh restart [project]

# Add Grafana with database access
./deploy_mmp_local.sh add-grafana [project]

# Add SSL to existing deployment
./deploy_mmp_local.sh add-ssl [project]

# Display passwords securely
./deploy_mmp_local.sh show-secrets [project]

# Complete cleanup
./deploy_mmp_local.sh cleanup [project]

# Docker cleanup
./deploy_mmp_local.sh docker-cleanup
```

## What It Does

- **Automated local deployment** with improved password handling
- **Automatic setup** of Docker, permissions, and `/etc/hosts`
- **Official Frappe integration** using easy-install.py
- **Grafana integration** with database access for monitoring
- **Complete lifecycle management** from deploy to cleanup

## Security Improvements

- **No password exposure** in terminal output or command history
- **Protected credential storage** with file permissions (chmod 600)
- **Git protection** for all sensitive files via .gitignore
- **Separate secrets management** with dedicated show-secrets command
- **Clean connection info** files without embedded passwords

**Note:** HTTP mode is optimized for simple local development. Use `--ssl` flag for production-like HTTPS deployment with self-signed certificates.

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

## Grafana Integration

Add monitoring and analytics to your deployment:

```bash
# Add Grafana after deployment
./deploy_mmp_local.sh add-grafana mmp-local

# Access Grafana at http://localhost:3000
# Database connection details provided automatically
```

## SSL/HTTPS Support

Deploy with production-like SSL encryption using Traefik reverse proxy:

```bash
# Deploy with SSL from the start
./deploy_mmp_local.sh deploy --ssl

# Or add SSL to existing deployment
./deploy_mmp_local.sh add-ssl mmp-local
```

**SSL Features:**
- **Traefik reverse proxy** with SSL termination
- **Self-signed certificates** (valid for 365 days)
- **Automatic HTTP to HTTPS redirect**
- **Multiple domain support** (main site, Grafana, Traefik dashboard)

**Access with SSL:**
- Main site: `https://mmp.local`
- Grafana: `https://grafana.mmp.local` (if added)
- Traefik dashboard: `https://traefik.mmp.local:8081`

**Browser Security Warning:** Self-signed certificates will trigger security warnings. Click "Advanced" and "Accept Risk" to proceed - this is normal for local development.

## Files Created

**During deployment:**
- `~/project-connection-info.txt` - Safe connection details
- `~/project-secrets.txt` - Protected passwords (chmod 600)

**Script files:**
- `deploy_mmp_local.sh` - Main deployment script
- `mmp-ec2.yaml` - Production EC2 deployment config  
- `production-deployment-guide.md` - Manual deployment guide
- `archive/` - Previous script versions (reference only)

## Troubleshooting

**Docker permissions:** Logout/login if you get permission errors  
**Site not accessible:** Check `/etc/hosts` has your sitename  
**Container issues:** Use `docker ps` and `docker logs <container>`  
**Forgot passwords:** Run `./deploy_mmp_local.sh show-secrets project-name`

## Based On

Production deployment at `mmp.devburner.io` using official Frappe easy-install script with additional password protection and monitoring features for local development.