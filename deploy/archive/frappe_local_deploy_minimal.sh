#!/bin/bash

# Minimal Frappe Local Deployment Script
# Focuses only on essentials that easy-install.py needs

set -e

# Script configuration
EASY_INSTALL_URL="https://raw.githubusercontent.com/frappe/bench/develop/easy-install.py"
DEFAULT_PROJECT="mmp-local"
DEFAULT_SITENAME="mmp.local"
DEFAULT_EMAIL="admin@mmp.local"
MMP_IMAGE="devburner/mmp-erpnext"
MMP_TAG="latest"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
}

# Check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        error "This script should not be run as root. Please run as a regular user."
        exit 1
    fi
}

# Install minimal dependencies that easy-install actually needs
install_minimal_deps() {
    log "Installing minimal dependencies..."
    sudo apt-get update
    sudo apt-get install -y curl wget python3
    log "Minimal dependencies installed"
}

# Download easy-install.py script
download_easy_install() {
    log "Downloading easy-install.py script..."
    wget -O /tmp/easy-install.py "$EASY_INSTALL_URL"
    chmod +x /tmp/easy-install.py
    log "easy-install.py downloaded"
}

# Deploy using easy-install with MMP defaults
deploy_frappe() {
    log "Starting MMP deployment with easy-install.py..."
    
    local deploy_cmd="python3 /tmp/easy-install.py deploy"
    deploy_cmd="$deploy_cmd --project ${PROJECT_NAME:-$DEFAULT_PROJECT}"
    deploy_cmd="$deploy_cmd --sitename ${SITE_NAME:-$DEFAULT_SITENAME}"
    deploy_cmd="$deploy_cmd --email ${ADMIN_EMAIL:-$DEFAULT_EMAIL}"
    deploy_cmd="$deploy_cmd --no-ssl --http-port ${HTTP_PORT:-8080}"
    deploy_cmd="$deploy_cmd --app erpnext"
    deploy_cmd="$deploy_cmd --image ${CUSTOM_IMAGE:-$MMP_IMAGE}"
    deploy_cmd="$deploy_cmd --version ${CUSTOM_TAG:-$MMP_TAG}"
    
    log "Running: $deploy_cmd"
    
    if eval "$deploy_cmd"; then
        log "MMP deployment completed successfully"
        show_summary
    else
        error "MMP deployment failed"
        exit 1
    fi
}

# Setup local hostname resolution
setup_local_dns() {
    local site_name="${SITE_NAME:-$DEFAULT_SITENAME}"
    if [[ "$site_name" == *".local" ]]; then
        log "Setting up local DNS resolution for $site_name..."
        if ! grep -q "$site_name" /etc/hosts; then
            echo "127.0.0.1 $site_name" | sudo tee -a /etc/hosts
            log "Added $site_name to /etc/hosts"
        else
            log "$site_name already exists in /etc/hosts"
        fi
    fi
}

# Show deployment summary
show_summary() {
    local project_name="${PROJECT_NAME:-$DEFAULT_PROJECT}"
    local site_name="${SITE_NAME:-$DEFAULT_SITENAME}"
    local http_port="${HTTP_PORT:-8080}"
    
    echo
    log "=== Deployment Summary ==="
    log "Project: $project_name"
    log "Site: $site_name"
    log "Access URL: http://$site_name:$http_port"
    log "Passwords: $HOME/${project_name}-passwords.txt"
    echo
    log "Useful commands:"
    log "  docker ps"
    log "  docker logs ${project_name}-backend-1"
    log "  docker exec -it ${project_name}-backend-1 bash"
    echo
}

# Parse simple arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --project) PROJECT_NAME="$2"; shift 2 ;;
        --site) SITE_NAME="$2"; shift 2 ;;
        --email) ADMIN_EMAIL="$2"; shift 2 ;;
        --port) HTTP_PORT="$2"; shift 2 ;;
        --image) CUSTOM_IMAGE="$2"; shift 2 ;;
        --tag) CUSTOM_TAG="$2"; shift 2 ;;
        *) shift ;;
    esac
done

# Main execution
main() {
    log "Starting minimal MMP deployment"
    
    check_root
    install_minimal_deps
    download_easy_install
    deploy_frappe
    setup_local_dns
    
    log "Deployment completed!"
}

main "$@"