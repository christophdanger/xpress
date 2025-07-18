# Local SSL with Traefik

This directory contains everything needed to add SSL support to your local MMP deployment using Traefik with self-signed certificates.

## Approach Overview

**Based on frappe_docker's Traefik approach but adapted for local development:**

- Uses Traefik v2.11 as reverse proxy (same as production)
- Self-signed certificates instead of Let's Encrypt
- Automatic HTTP to HTTPS redirect
- Supports multiple services (ERPNext, Grafana, Traefik dashboard)
- Maintains consistency with production architecture

## Quick Start

```bash
# 1. Generate certificates
./ssl-options/generate-selfsigned-certs.sh mmp.local

# 2. Deploy with SSL (when we add this to main script)
./deploy_mmp_local.sh add-ssl mmp-local

# 3. Access via HTTPS
https://mmp.local
https://grafana.mmp.local
https://traefik.mmp.local:8080
```

## What Gets Created

### Generated Files
- `ssl-certs/cert.pem` - SSL certificate (valid 365 days)
- `ssl-certs/key.pem` - Private key (chmod 600)
- `project-ssl-compose.yml` - SSL Docker compose override

### Services & URLs
- **ERPNext**: `https://mmp.local` (main application)
- **Grafana**: `https://grafana.mmp.local` (monitoring)
- **Traefik Dashboard**: `https://traefik.mmp.local:8080` (proxy admin)

### /etc/hosts Entries
```
127.0.0.1 mmp.local
127.0.0.1 grafana.mmp.local
127.0.0.1 traefik.mmp.local
```

## Architecture

```
Browser → Traefik (443) → ERPNext (8080)
                       → Grafana (3000)
                       → Dashboard (8080)
```

**Key Components:**

1. **Traefik Container**: Reverse proxy with SSL termination
2. **Dynamic Configuration**: TLS settings and redirect rules
3. **Service Labels**: Routes requests to appropriate containers
4. **Self-Signed Certificates**: Local development certificates

## Files Explained

### `local-ssl-addon.yml`
Docker compose override that adds Traefik and configures SSL routing. Based on frappe_docker patterns but adapted for local self-signed certificates.

### `traefik-dynamic.yaml`
Static configuration for:
- Certificate locations
- TLS security settings
- HTTP to HTTPS redirect middleware

### `generate-selfsigned-certs.sh`
Creates certificates with OpenSSL including:
- Main domain and wildcard
- Service subdomains (grafana, traefik)
- localhost and IP addresses
- 365-day validity

## Browser Warnings

Since these are self-signed certificates, browsers will show security warnings:

1. **Chrome/Edge**: Click "Advanced" → "Proceed to mmp.local (unsafe)"
2. **Firefox**: Click "Advanced" → "Accept the Risk and Continue"
3. **Safari**: Click "Show Details" → "Visit Website"

This is normal for local development with self-signed certificates.

## Production Differences

**Local Development:**
- Self-signed certificates (manual acceptance)
- HTTP and HTTPS on same ports
- Local domain names (.local)

**Production:**
- Let's Encrypt certificates (automatic trust)
- SSL-only with redirects
- Public domain names

**Architecture stays the same** - Traefik handles SSL termination and routing in both environments.

## Advantages of This Approach

1. **Consistency**: Same Traefik setup as production
2. **Security**: Encrypted local traffic
3. **Realistic**: Tests SSL redirects and headers
4. **Flexibility**: Easy to add new services
5. **Familiar**: Uses proven frappe_docker patterns

## Next Steps

This SSL approach is ready to integrate into the main deployment script with an `add-ssl` command that would:

1. Generate certificates if needed
2. Create SSL compose override
3. Restart deployment with SSL enabled
4. Update connection info files

The approach maintains the same operational simplicity while adding production-like SSL handling.