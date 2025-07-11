#!/bin/bash

# Frappe Local Deployment Script
# This script automates the deployment of Frappe/ERPNext on a local Ubuntu system
# Based on the production deployment guide and addresses common deployment issues

set -e

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="/var/log/frappe-local-deploy.log"
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
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] $1${NC}"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

warn() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] WARNING: $1" >> "$LOG_FILE"
}

error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1" >> "$LOG_FILE"
}

info() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')] INFO: $1${NC}"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: $1" >> "$LOG_FILE"
}

# Check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        error "This script should not be run as root. Please run as a regular user with sudo privileges."
        exit 1
    fi
}

# Check if running on Ubuntu
check_ubuntu() {
    if ! grep -q "Ubuntu" /etc/os-release; then
        error "This script is designed for Ubuntu systems only."
        exit 1
    fi
    local ubuntu_version=$(grep VERSION_ID /etc/os-release | cut -d'"' -f2)
    log "Detected Ubuntu $ubuntu_version"
}

# Check if user has sudo privileges
check_sudo() {
    if ! sudo -n true 2>/dev/null; then
        error "User $(whoami) does not have sudo privileges. Please ensure the user is in the sudo group."
        exit 1
    fi
    log "User $(whoami) has sudo privileges"
}

# Install system dependencies
install_system_deps() {
    log "Installing system dependencies..."
    sudo apt-get update
    sudo apt-get install -y \
        curl \
        wget \
        git \
        python3 \
        python3-pip \
        software-properties-common \
        apt-transport-https \
        ca-certificates \
        gnupg \
        lsb-release
    log "System dependencies installed"
}

# Install Docker with proper group handling
install_docker() {
    if command -v docker &> /dev/null; then
        log "Docker is already installed"
        
        # Just ensure Docker service is running (let easy-install handle the rest)
        if sudo systemctl is-active docker &>/dev/null; then
            log "Docker service is running"
        else
            log "Starting Docker service..."
            sudo systemctl start docker 2>/dev/null || warn "Could not start Docker via systemctl - easy-install will handle this"
        fi
    else
        log "Installing Docker..."
        curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
        sudo sh /tmp/get-docker.sh
        rm /tmp/get-docker.sh
        log "Docker installation completed"
    fi
    
    # Add current user to docker group if not already there
    if ! groups "$USER" | grep -q docker; then
        log "Adding user $(whoami) to docker group..."
        sudo usermod -aG docker "$USER"
        warn "User added to docker group. You may need to log out and back in for changes to take effect."
        warn "If the deployment fails with permission errors, try: newgrp docker"
    else
        log "User $(whoami) is already in the docker group"
    fi
}

# Test Docker functionality (simplified)
test_docker() {
    log "Testing Docker functionality..."
    
    # Basic test: Check if Docker daemon is accessible
    if docker version &> /dev/null; then
        log "Docker is accessible"
    else
        warn "Docker test failed - easy-install will handle Docker setup"
        warn "If you get permission errors, try: newgrp docker"
    fi
}

# Install Docker Compose
install_docker_compose() {
    if docker compose version &> /dev/null; then
        log "Docker Compose is already available"
        return 0
    fi

    log "Installing Docker Compose..."
    # For newer Docker installations, Compose is included as a plugin
    # For older installations, install it manually
    if ! docker compose version &> /dev/null; then
        local compose_version="v2.24.0"
        sudo curl -L "https://github.com/docker/compose/releases/download/${compose_version}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
        
        # Also install as Docker plugin
        mkdir -p ~/.docker/cli-plugins
        sudo cp /usr/local/bin/docker-compose ~/.docker/cli-plugins/docker-compose
        
        log "Docker Compose installed"
    fi
}

# Download easy-install.py script
download_easy_install() {
    log "Downloading easy-install.py script..."
    wget -O /tmp/easy-install.py "$EASY_INSTALL_URL"
    chmod +x /tmp/easy-install.py
    log "easy-install.py downloaded"
}

# Interactive configuration with menus
get_deployment_config() {
    echo
    info "=== MMP Local Deployment Configuration ==="
    echo
    
    # Project name
    info "Project Configuration:"
    echo "Common project names:"
    echo "- mmp-local (recommended for MMP development)"
    echo "- erp-local (ERP-focused development)"
    echo "- frappe-dev (general Frappe development)"
    read -p "Project name [$DEFAULT_PROJECT]: " PROJECT_NAME
    PROJECT_NAME=${PROJECT_NAME:-$DEFAULT_PROJECT}
    echo
    
    # Site name with suggestions
    info "Site Configuration:"
    echo "Site naming patterns for local development:"
    echo "- mmp.local (matches MMP branding)"
    echo "- erp.local (ERP-focused)"
    echo "- app.local (generic app development)"
    echo "- localhost (simple localhost access)"
    read -p "Site name [$DEFAULT_SITENAME]: " SITE_NAME
    SITE_NAME=${SITE_NAME:-$DEFAULT_SITENAME}
    echo
    
    # Admin email
    info "Admin Configuration:"
    echo "Admin email (used for notifications and login):"
    read -p "Admin email [$DEFAULT_EMAIL]: " ADMIN_EMAIL
    ADMIN_EMAIL=${ADMIN_EMAIL:-$DEFAULT_EMAIL}
    echo
    
    # Docker image selection
    info "Docker Image Selection:"
    echo "Choose your Docker image:"
    echo "1) devburner/mmp-erpnext:latest (Production MMP image - recommended)"
    echo "2) frappe/erpnext:latest (Standard ERPNext)"
    echo "3) frappe/frappe:latest (Base Frappe without ERPNext)"
    echo "4) Custom image"
    read -p "Choice [1]: " IMAGE_CHOICE
    IMAGE_CHOICE=${IMAGE_CHOICE:-1}
    
    case $IMAGE_CHOICE in
        1)
            CUSTOM_IMAGE="$MMP_IMAGE"
            CUSTOM_TAG="$MMP_TAG"
            INSTALL_ERPNEXT="y"
            info "Selected: MMP Production Image (includes ERPNext + MMP customizations)"
            ;;
        2)
            CUSTOM_IMAGE="frappe/erpnext"
            CUSTOM_TAG="latest"
            INSTALL_ERPNEXT="y"
            info "Selected: Standard ERPNext"
            ;;
        3)
            CUSTOM_IMAGE="frappe/frappe"
            CUSTOM_TAG="latest"
            INSTALL_ERPNEXT="n"
            info "Selected: Base Frappe (no ERPNext)"
            ;;
        4)
            read -p "Custom image name: " CUSTOM_IMAGE
            read -p "Custom image tag [latest]: " CUSTOM_TAG
            CUSTOM_TAG=${CUSTOM_TAG:-latest}
            read -p "Install ERPNext? (y/N): " INSTALL_ERPNEXT
            INSTALL_ERPNEXT=${INSTALL_ERPNEXT:-n}
            ;;
        *)
            warn "Invalid choice, using default MMP image"
            CUSTOM_IMAGE="$MMP_IMAGE"
            CUSTOM_TAG="$MMP_TAG"
            INSTALL_ERPNEXT="y"
            ;;
    esac
    echo
    
    # SSL configuration
    info "SSL Configuration:"
    echo "SSL/HTTPS setup:"
    echo "- No SSL: Quick setup, HTTP only (recommended for local development)"
    echo "- SSL: HTTPS with certificates (for production-like testing)"
    read -p "Use SSL/HTTPS? (N/y): " USE_SSL
    USE_SSL=${USE_SSL:-n}
    
    if [[ "$USE_SSL" != "y" ]]; then
        echo "HTTP port options:"
        echo "- 8080: Standard development port"
        echo "- 3000: Alternative development port"
        echo "- 80: Standard HTTP port (requires sudo)"
        read -p "HTTP port [8080]: " HTTP_PORT
        HTTP_PORT=${HTTP_PORT:-8080}
    fi
    echo
    
    # Additional apps
    info "Additional Apps:"
    echo "Install additional applications?"
    echo "Note: MMP image already includes ERPNext and custom MMP apps"
    read -p "Install additional apps? (N/y): " INSTALL_ADDITIONAL
    INSTALL_ADDITIONAL=${INSTALL_ADDITIONAL:-n}
    
    ADDITIONAL_APPS=()
    if [[ "$INSTALL_ADDITIONAL" == "y" ]]; then
        echo "Common additional apps:"
        echo "- hrms (Human Resources)"
        echo "- payments (Payment Integration)"
        echo "- ecommerce (E-commerce)"
        echo "Enter app names (one per line, empty line to finish):"
        while true; do
            read -p "App name: " app_name
            if [[ -z "$app_name" ]]; then
                break
            fi
            ADDITIONAL_APPS+=("$app_name")
        done
    fi
    echo
    
    # Show configuration summary
    info "=== Configuration Summary ==="
    echo
    info "Project: $PROJECT_NAME"
    info "Site: $SITE_NAME"
    info "Admin Email: $ADMIN_EMAIL"
    info "Docker Image: $CUSTOM_IMAGE:$CUSTOM_TAG"
    info "ERPNext: $INSTALL_ERPNEXT"
    info "SSL: $USE_SSL"
    if [[ "$USE_SSL" != "y" ]]; then
        info "HTTP Port: $HTTP_PORT"
    fi
    if [[ ${#ADDITIONAL_APPS[@]} -gt 0 ]]; then
        info "Additional Apps: ${ADDITIONAL_APPS[*]}"
    fi
    echo
    
    # Final confirmation
    read -p "Continue with deployment? (y/N): " CONFIRM
    if [[ "$CONFIRM" != "y" ]]; then
        log "Deployment cancelled by user"
        exit 0
    fi
}

# Deploy Frappe using easy-install.py
deploy_frappe() {
    log "Starting MMP deployment..."
    
    # Build the easy-install command
    local deploy_cmd="python3 /tmp/easy-install.py deploy"
    deploy_cmd="$deploy_cmd --project $PROJECT_NAME"
    deploy_cmd="$deploy_cmd --sitename $SITE_NAME"
    deploy_cmd="$deploy_cmd --email $ADMIN_EMAIL"
    
    if [[ "$USE_SSL" != "y" ]]; then
        deploy_cmd="$deploy_cmd --no-ssl --http-port $HTTP_PORT"
    fi
    
    if [[ "$INSTALL_ERPNEXT" == "y" ]]; then
        deploy_cmd="$deploy_cmd --app erpnext"
    fi
    
    # Add additional apps
    for app in "${ADDITIONAL_APPS[@]}"; do
        deploy_cmd="$deploy_cmd --app $app"
    done
    
    if [[ -n "$CUSTOM_IMAGE" ]]; then
        deploy_cmd="$deploy_cmd --image $CUSTOM_IMAGE"
        if [[ -n "$CUSTOM_TAG" ]]; then
            deploy_cmd="$deploy_cmd --version $CUSTOM_TAG"
        fi
    fi
    
    log "Running deployment command: $deploy_cmd"
    
    # Execute the deployment
    if eval "$deploy_cmd"; then
        log "MMP deployment completed successfully"
    else
        error "MMP deployment failed"
        exit 1
    fi
}

# Setup local hostname resolution
setup_local_dns() {
    if [[ "$SITE_NAME" == *".local" ]]; then
        log "Setting up local DNS resolution for $SITE_NAME..."
        
        # Check if entry already exists
        if ! grep -q "$SITE_NAME" /etc/hosts; then
            log "Adding $SITE_NAME to /etc/hosts"
            echo "127.0.0.1 $SITE_NAME" | sudo tee -a /etc/hosts
        else
            log "$SITE_NAME already exists in /etc/hosts"
        fi
    fi
}

# Verify deployment
verify_deployment() {
    log "Verifying deployment..."
    
    # Check if containers are running
    if ! docker ps | grep -q "$PROJECT_NAME"; then
        error "No containers found for project $PROJECT_NAME"
        return 1
    fi
    
    # Check container health
    local failed_containers=()
    for container in $(docker ps --format "table {{.Names}}" | grep "^$PROJECT_NAME" | tail -n +2); do
        if ! docker ps | grep "$container" | grep -q "Up"; then
            failed_containers+=("$container")
        fi
    done
    
    if [[ ${#failed_containers[@]} -gt 0 ]]; then
        error "Some containers are not running properly:"
        for container in "${failed_containers[@]}"; do
            error "  - $container"
        done
        return 1
    fi
    
    log "All containers are running successfully"
    return 0
}

# Show deployment summary
show_deployment_summary() {
    echo
    info "=== Deployment Summary ==="
    echo
    
    # Show passwords
    local passwords_file="$HOME/${PROJECT_NAME}-passwords.txt"
    if [[ -f "$passwords_file" ]]; then
        info "Passwords saved to: $passwords_file"
        echo
        cat "$passwords_file"
        echo
    else
        warn "Passwords file not found at: $passwords_file"
    fi
    
    # Show access information
    local access_url
    if [[ "$USE_SSL" == "y" ]]; then
        access_url="https://$SITE_NAME"
    else
        access_url="http://$SITE_NAME:$HTTP_PORT"
    fi
    
    info "Project: $PROJECT_NAME"
    info "Site: $SITE_NAME"
    info "Access URL: $access_url"
    info "Compose file: $HOME/${PROJECT_NAME}-compose.yml"
    info "Environment file: $HOME/${PROJECT_NAME}.env"
    info "Log file: $LOG_FILE"
    
    echo
    info "=== Useful Commands ==="
    info "View containers:    docker ps"
    info "View logs:          docker logs ${PROJECT_NAME}-backend-1"
    info "Access backend:     docker exec -it ${PROJECT_NAME}-backend-1 bash"
    info "Stop deployment:    docker compose -p $PROJECT_NAME down"
    info "Restart deployment: docker compose -p $PROJECT_NAME up -d"
    info "View compose file:  cat $HOME/${PROJECT_NAME}-compose.yml"
    
    echo
    info "=== MMP-Specific Commands ==="
    info "List installed apps: docker exec ${PROJECT_NAME}-backend-1 bench --site $SITE_NAME list-apps"
    info "Check MMP apps:      docker exec ${PROJECT_NAME}-backend-1 ls -la /home/frappe/frappe-bench/apps/"
    info "MMP site console:    docker exec -it ${PROJECT_NAME}-backend-1 bench --site $SITE_NAME console"
    info "Update MMP apps:     docker exec ${PROJECT_NAME}-backend-1 bench --site $SITE_NAME migrate"
    
    echo
    info "=== Bench Commands (inside container) ==="
    info "List sites:         bench --site all list-sites"
    info "Create new site:    bench new-site example.com"
    info "Install app:        bench --site example.com install-app app_name"
    info "Backup site:        bench --site example.com backup"
    info "Restore backup:     bench --site example.com restore backup_file"
    
    echo
    if [[ "$SITE_NAME" == *".local" ]]; then
        info "=== Local Development Notes ==="
        info "- Site configured for local development"
        info "- DNS entry added to /etc/hosts"
        info "- No SSL certificate needed for .local domains"
        info "- MMP customizations included in Docker image"
        info "- Production-like environment for development"
    fi
    
    echo
}

# Cleanup deployment
cleanup_deployment() {
    local project_name="${1:-}"
    
    if [[ -z "$project_name" ]]; then
        read -p "Enter project name to cleanup: " project_name
    fi
    
    if [[ -z "$project_name" ]]; then
        error "Project name is required"
        return 1
    fi
    
    warn "This will remove all containers, volumes, and data for project: $project_name"
    read -p "Are you sure? (y/N): " CONFIRM
    if [[ "$CONFIRM" != "y" ]]; then
        log "Cleanup cancelled"
        return 0
    fi
    
    log "Stopping and removing containers for project: $project_name"
    
    # Stop containers
    if docker ps -q --filter "name=$project_name" | grep -q .; then
        docker stop $(docker ps -q --filter "name=$project_name") 2>/dev/null || true
    fi
    
    # Remove containers
    if docker ps -aq --filter "name=$project_name" | grep -q .; then
        docker rm $(docker ps -aq --filter "name=$project_name") 2>/dev/null || true
    fi
    
    # Remove volumes
    log "Removing project volumes..."
    if docker volume ls -q | grep -q "^${project_name}_"; then
        docker volume ls -q | grep "^${project_name}_" | xargs docker volume rm 2>/dev/null || true
    fi
    
    # Remove networks
    log "Removing project networks..."
    if docker network ls --format "{{.Name}}" | grep -q "^${project_name}_"; then
        docker network ls --format "{{.Name}}" | grep "^${project_name}_" | xargs docker network rm 2>/dev/null || true
    fi
    
    # Clean up project files
    log "Cleaning up project files..."
    rm -f "$HOME/${project_name}-compose.yml"
    rm -f "$HOME/${project_name}.env"
    rm -f "$HOME/${project_name}-passwords.txt"
    
    # Remove from /etc/hosts if it's a .local domain
    if [[ -f /etc/hosts ]]; then
        local site_entries=$(grep -l "\.local" "$HOME/${project_name}.env" 2>/dev/null || true)
        if [[ -n "$site_entries" ]]; then
            warn "Removing .local entries from /etc/hosts..."
            sudo sed -i '/\.local.*# Added by frappe deployment/d' /etc/hosts 2>/dev/null || true
        fi
    fi
    
    log "Cleanup completed for project: $project_name"
}

# Docker cleanup
docker_cleanup() {
    warn "This will remove all unused Docker containers, networks, images, and volumes"
    read -p "Continue? (y/N): " CONFIRM
    if [[ "$CONFIRM" != "y" ]]; then
        log "Docker cleanup cancelled"
        return 0
    fi
    
    log "Running Docker system cleanup..."
    
    # Remove stopped containers
    docker container prune -f
    
    # Remove unused networks
    docker network prune -f
    
    # Remove unused images
    docker image prune -a -f
    
    # Remove unused volumes
    docker volume prune -f
    
    log "Docker cleanup completed"
}

# Complete Docker uninstall
uninstall_docker() {
    warn "This will completely remove Docker and all associated data"
    read -p "Are you sure? (y/N): " CONFIRM
    if [[ "$CONFIRM" != "y" ]]; then
        log "Docker uninstall cancelled"
        return 0
    fi
    
    log "Stopping all Docker containers..."
    docker stop $(docker ps -aq) 2>/dev/null || true
    
    log "Removing all Docker containers..."
    docker rm $(docker ps -aq) 2>/dev/null || true
    
    log "Removing all Docker images..."
    docker rmi $(docker images -q) 2>/dev/null || true
    
    log "Removing all Docker volumes..."
    docker volume rm $(docker volume ls -q) 2>/dev/null || true
    
    log "Uninstalling Docker packages..."
    sudo apt-get purge -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-ce-rootless-extras 2>/dev/null || true
    sudo apt-get autoremove -y
    
    log "Removing Docker data directory..."
    sudo rm -rf /var/lib/docker
    sudo rm -rf /var/lib/containerd
    
    log "Removing user from docker group..."
    sudo deluser "$USER" docker 2>/dev/null || true
    
    log "Docker uninstall completed"
}

# Show help
show_help() {
    cat << EOF
MMP Local Deployment Script

Usage: $0 [COMMAND] [OPTIONS]

Commands:
  deploy          Deploy MMP/ERPNext locally (default)
  cleanup         Remove a specific deployment
  docker-cleanup  Remove all unused Docker resources
  uninstall       Completely remove Docker
  verify          Verify an existing deployment
  help            Show this help message

Options:
  --project       Project name (default: mmp-local)
  --site          Site name (default: mmp.local)
  --email         Admin email (default: admin@mmp.local)
  --ssl           Use SSL/HTTPS (y/n, default: n)
  --port          HTTP port when not using SSL (default: 8080)
  --image         Custom Docker image (default: devburner/mmp-erpnext)
  --tag           Custom image tag (default: latest)
  --non-interactive  Run without prompts (uses defaults or provided options)

Examples:
  $0 deploy                    # Interactive deployment with menus
  $0 deploy --non-interactive  # Quick deployment with defaults
  $0 cleanup --project mmp-local
  $0 docker-cleanup
  $0 uninstall

MMP Deployment Notes:
- Default uses the production MMP image (devburner/mmp-erpnext:latest)
- Includes ERPNext and custom MMP applications
- Configured for local development with .local domains
- SSL is typically not needed for local development
- The script will automatically add .local domains to /etc/hosts

Interactive Features:
- Menu-driven Docker image selection
- Contextual help for each configuration option
- Smart defaults based on production MMP setup
- Additional app installation support

EOF
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --project)
                PROJECT_NAME="$2"
                shift 2
                ;;
            --site)
                SITE_NAME="$2"
                shift 2
                ;;
            --email)
                ADMIN_EMAIL="$2"
                shift 2
                ;;
            --erpnext)
                INSTALL_ERPNEXT="$2"
                shift 2
                ;;
            --ssl)
                USE_SSL="$2"
                shift 2
                ;;
            --port)
                HTTP_PORT="$2"
                shift 2
                ;;
            --image)
                CUSTOM_IMAGE="$2"
                shift 2
                ;;
            --tag)
                CUSTOM_TAG="$2"
                shift 2
                ;;
            --non-interactive)
                NON_INTERACTIVE="true"
                shift
                ;;
            *)
                shift
                ;;
        esac
    done
}

# Main deployment function
main_deploy() {
    log "Starting MMP local deployment"
    
    # System checks
    check_root
    check_ubuntu
    check_sudo
    
    # Install system dependencies
    install_system_deps
    
    # Install Docker with proper group handling
    install_docker
    
    # Test Docker functionality
    test_docker
    
    # Install Docker Compose
    install_docker_compose
    
    # Download easy-install script
    download_easy_install
    
    # Get configuration (interactive or use defaults)
    if [[ "$NON_INTERACTIVE" != "true" ]]; then
        get_deployment_config
    else
        PROJECT_NAME=${PROJECT_NAME:-$DEFAULT_PROJECT}
        SITE_NAME=${SITE_NAME:-$DEFAULT_SITENAME}
        ADMIN_EMAIL=${ADMIN_EMAIL:-$DEFAULT_EMAIL}
        CUSTOM_IMAGE=${CUSTOM_IMAGE:-$MMP_IMAGE}
        CUSTOM_TAG=${CUSTOM_TAG:-$MMP_TAG}
        INSTALL_ERPNEXT=${INSTALL_ERPNEXT:-y}
        USE_SSL=${USE_SSL:-n}
        HTTP_PORT=${HTTP_PORT:-8080}
        ADDITIONAL_APPS=()
        
        log "Using non-interactive mode with MMP defaults"
        log "Image: $CUSTOM_IMAGE:$CUSTOM_TAG"
    fi
    
    # Deploy Frappe
    deploy_frappe
    
    # Setup local DNS for .local domains
    setup_local_dns
    
    # Verify deployment
    if verify_deployment; then
        log "Deployment verification successful"
    else
        warn "Deployment verification failed - check logs for details"
    fi
    
    # Show deployment summary
    show_deployment_summary
    
    log "Deployment process completed successfully"
}

# Main script logic
main() {
    # Ensure log file exists and is writable
    sudo touch "$LOG_FILE" 2>/dev/null || touch "$LOG_FILE"
    if [[ -f "$LOG_FILE" ]]; then
        sudo chown "$USER:$USER" "$LOG_FILE" 2>/dev/null || true
    fi
    
    # Parse command line arguments
    parse_args "$@"
    
    # Handle commands
    case "${1:-deploy}" in
        deploy)
            main_deploy
            ;;
        cleanup)
            cleanup_deployment "$PROJECT_NAME"
            ;;
        docker-cleanup)
            docker_cleanup
            ;;
        uninstall)
            uninstall_docker
            ;;
        verify)
            if [[ -n "$PROJECT_NAME" ]]; then
                verify_deployment
            else
                read -p "Project name to verify: " PROJECT_NAME
                verify_deployment
            fi
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            error "Unknown command: $1"
            show_help
            exit 1
            ;;
    esac
}

# Run main function
main "$@"