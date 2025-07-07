# Production Deployment Guide: Custom Frappe Apps with Docker

## Overview

This guide provides a comprehensive approach to deploying custom Frappe applications alongside ERPNext in production using Docker. It addresses common pain points and provides practical troubleshooting steps that supplement the official Frappe documentation.

## Architecture

Our deployment strategy separates the build and deployment phases for better reliability and parallelization:

1. **Build Phase**: Create custom Docker image with all required apps
2. **Deploy Phase**: Use Frappe's easy-install script with the custom image
3. **Verification Phase**: Validate deployment and troubleshoot issues

## Prerequisites

- Docker and Docker Compose installed
- Domain name with DNS pointing to your server
- GitHub account with container registry access (or Docker Hub)
- EC2 instance (or similar) with public IP

## Phase 1: Build Custom Docker Image

### 1.1 Prepare Apps Configuration

Create an `apps.json` file with your required applications:

```json
[
  {
    "url": "https://github.com/frappe/erpnext",
    "branch": "version-15"
  },
  {
    "url": "https://github.com/yourusername/your-custom-app",
    "branch": "main"
  }
]
```

### 1.2 Build Process

```bash
# Clone frappe_docker repository
git clone https://github.com/frappe/frappe_docker.git
cd frappe_docker

# Create base64 encoded apps.json
export APPS_JSON_BASE64=$(base64 -w 0 apps.json)

# Verify encoding (optional but recommended)
echo "Encoded apps.json: $APPS_JSON_BASE64"

# Build custom image with verbose output
docker build \
  --build-arg=FRAPPE_PATH=https://github.com/frappe/frappe \
  --build-arg=FRAPPE_BRANCH=version-15 \
  --build-arg=APPS_JSON_BASE64="$APPS_JSON_BASE64" \
  --tag=yourusername/your-app-name:latest \
  --file=images/layered/Containerfile \
  --progress=plain \
  .
```

### 1.3 Push to Registry

```bash
# Push to Docker Hub or GitHub Container Registry
docker push yourusername/your-app-name:latest
```

### 1.4 Build Verification

Verify your apps were included in the build output:
- Look for `Cloning into 'erpnext'...`
- Look for `Cloning into 'your-custom-app'...`

## Phase 2: Production Deployment

### 2.1 Server Preparation

```bash
# Install Docker (if not already installed)
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Download easy-install script
wget https://raw.githubusercontent.com/frappe/bench/develop/easy-install.py
```

### 2.2 DNS Configuration

Ensure your domain points to your server's public IP:
```bash
# Verify DNS resolution
nslookup your-domain.com
dig your-domain.com
```

### 2.3 Deploy Command

```bash
python3 easy-install.py deploy \
  --project=your-project-name \
  --email=your-email@domain.com \
  --sitename=your-domain.com \
  --image=yourusername/your-app-name \
  --version=latest \
  --app=erpnext \
  --app=your_custom_app
```

## Phase 3: Troubleshooting & Verification

### 3.1 Container Status Check

```bash
# Check all containers are running
docker ps

# Check logs for specific containers
docker logs your-project-backend-1 --tail 50
docker logs your-project-proxy-1 --tail 50
```

### 3.2 App Installation Verification

```bash
# Check what apps are installed
docker exec your-project-backend-1 ls -la /home/frappe/frappe-bench/apps/

# Check apps.txt file
docker exec your-project-backend-1 cat /home/frappe/frappe-bench/sites/apps.txt

# Search for specific app directories
docker exec your-project-backend-1 find /home/frappe/frappe-bench -name "your_custom_app" -type d
```

### 3.3 Site Status Verification

```bash
# List all sites
docker exec your-project-backend-1 bench list-sites

# Check site status
docker exec your-project-backend-1 bench --site your-domain.com show-config
```

## Common Issues & Solutions

### Issue 1: SSL Certificate Rate Limiting

**Problem**: `too many certificates (5) already issued for this exact set of identifiers`

**Solution**: 
- Use a different subdomain (e.g., `app.yourdomain.com` instead of `erp.yourdomain.com`)
- Wait for rate limit to reset (168 hours)
- Use staging environment for testing

### Issue 2: Module Not Found Errors

**Problem**: `ModuleNotFoundError: No module named 'your_app'`

**Diagnosis**:
```bash
# Check if apps were properly built into image
docker exec your-project-backend-1 ls -la /home/frappe/frappe-bench/apps/

# Check Python path and imports
docker exec your-project-backend-1 python -c "import your_app; print('Success')"
```

**Solution**: Rebuild image ensuring apps.json is properly encoded and all apps clone successfully.

### Issue 3: Site Already Exists

**Problem**: Site creation fails because domain already exists

**Solution**:
```bash
# Clean slate approach - remove all data
docker-compose -p your-project down
docker volume rm your-project_db-data your-project_sites
docker container prune -f
docker image rm yourusername/your-app-name:latest
```

### Issue 4: Database Connection Issues

**Problem**: Database connection errors during site operations

**Diagnosis**:
```bash
# Check database container status
docker logs your-project-db-1 --tail 50

# Test database connectivity
docker exec your-project-backend-1 bench --site your-domain.com doctor
```

**Solution**: Ensure all containers are healthy and networking is properly configured.

## Advanced Troubleshooting Commands

### Container Deep Dive

```bash
# Execute shell in backend container
docker exec -it your-project-backend-1 bash

# Check bench status
docker exec your-project-backend-1 bench status

# Check site configuration
docker exec your-project-backend-1 bench --site your-domain.com show-config

# Check app installation status
docker exec your-project-backend-1 bench --site your-domain.com list-apps
```

### Database Operations

```bash
# Access database directly
docker exec -it your-project-db-1 mysql -u root -p

# Check database tables for your app
docker exec your-project-backend-1 bench --site your-domain.com mariadb
```

### Log Analysis

```bash
# Real-time log monitoring
docker logs -f your-project-backend-1

# Search for specific errors
docker logs your-project-backend-1 2>&1 | grep -i error

# Check multiple containers simultaneously
docker-compose -p your-project logs -f
```

## Performance & Monitoring

### Resource Monitoring

```bash
# Check container resource usage
docker stats

# Check disk usage
docker system df

# Check volume usage
docker volume ls
```

### Health Checks

```bash
# Test site accessibility
curl -I https://your-domain.com

# Check specific endpoints
curl https://your-domain.com/api/method/ping
```

## Best Practices

### 1. Testing Strategy

- Use staging domains for testing deployments
- Test image builds locally before pushing
- Verify all apps are included in build logs

### 2. Backup Strategy

```bash
# Backup site data
docker exec your-project-backend-1 bench --site your-domain.com backup

# Backup configuration
docker exec your-project-backend-1 cp -r sites/your-domain.com/site_config.json /tmp/
```

### 3. Update Strategy

```bash
# Update apps in existing deployment
docker exec your-project-backend-1 bench get-app your-new-app
docker exec your-project-backend-1 bench --site your-domain.com install-app your-new-app
```

### 4. Security Considerations

- Use environment variables for sensitive data
- Regularly update base images
- Monitor logs for security issues
- Use proper firewall rules

## Environment Variables Reference

Key environment variables for customization:

```bash
# SSL Configuration
LETSENCRYPT_STAGING=true  # Use for testing

# Database Configuration
DB_ROOT_PASSWORD=your-secure-password

# Email Configuration
MAIL_HOST=smtp.yourdomain.com
MAIL_PORT=587
```

## Production Checklist

- [ ] DNS pointing to correct IP
- [ ] Custom image built and pushed
- [ ] All required apps included in image
- [ ] SSL certificates working
- [ ] All containers running healthy
- [ ] Site accessible via HTTPS
- [ ] Custom apps visible in DocType list
- [ ] Backup strategy in place
- [ ] Monitoring configured

## Support & Additional Resources

- [Frappe Docker Repository](https://github.com/frappe/frappe_docker)
- [Frappe Bench Documentation](https://frappeframework.com/docs/user/en/bench)
- [ERPNext Documentation](https://docs.erpnext.com/)

---

This guide represents real-world experience deploying custom Frappe applications and addresses common pain points not covered in official documentation.