#!/bin/bash

# Streamlined Frappe Local Deployment Script
# Focuses on essentials while keeping instance management capabilities

set -e

# Configuration
EASY_INSTALL_URL="https://raw.githubusercontent.com/frappe/bench/develop/easy-install.py"
DEFAULT_PROJECT="mmp-local"
DEFAULT_SITENAME="mmp.local"
DEFAULT_EMAIL="admin@mmp.local"
DEFAULT_IMAGE="frappe/erpnext"
DEFAULT_TAG="v15"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${GREEN}[$(date '+%H:%M:%S')] $1${NC}"; }
warn() { echo -e "${YELLOW}[$(date '+%H:%M:%S')] WARNING: $1${NC}"; }
error() { echo -e "${RED}[$(date '+%H:%M:%S')] ERROR: $1${NC}"; exit 1; }

# Basic checks
check_requirements() {
    [[ $EUID -eq 0 ]] && error "Don't run as root"
    
    # Check for required packages, only install if missing
    local missing_packages=()
    command -v curl >/dev/null || missing_packages+=(curl)
    command -v wget >/dev/null || missing_packages+=(wget)
    command -v python3 >/dev/null || missing_packages+=(python3)
    
    if [[ ${#missing_packages[@]} -gt 0 ]]; then
        log "Installing missing packages: ${missing_packages[*]}"
        sudo apt-get update && sudo apt-get install -y "${missing_packages[@]}"
    fi
    
    # Check/setup Docker group
    if ! groups | grep -q docker; then
        if ! getent group docker >/dev/null; then
            sudo groupadd docker
        fi
        sudo usermod -aG docker "$USER"
        warn "Added to docker group. You may need to logout/login if Docker commands fail"
    fi
}

# Download easy-install if needed
download_easy_install() {
    if [[ ! -f /tmp/easy-install.py ]]; then
        log "Downloading easy-install.py"
        curl -fsSL "$EASY_INSTALL_URL" -o /tmp/easy-install.py
    fi
}

# Deploy function
deploy() {
    local project="${1:-$DEFAULT_PROJECT}"
    local sitename="${2:-$DEFAULT_SITENAME}"
    local email="${3:-$DEFAULT_EMAIL}"
    local image="${4:-$DEFAULT_IMAGE}"
    local tag="${5:-$DEFAULT_TAG}"
    
    log "Deploying $project with $image:$tag"
    
    check_requirements
    download_easy_install
    
    # Set custom image in env file if different from default
    if [[ "$image" != "$DEFAULT_IMAGE" ]]; then
        if [[ -f "/home/$USER/$project.env" ]]; then
            sed -i "s|CUSTOM_IMAGE=.*|CUSTOM_IMAGE=$image|" "/home/$USER/$project.env"
            sed -i "s|CUSTOM_TAG=.*|CUSTOM_TAG=$tag|" "/home/$USER/$project.env"
        fi
    fi
    
    python3 /tmp/easy-install.py deploy \
        --project "$project" \
        --sitename "$sitename" \
        --email "$email" \
        --no-ssl \
        --http-port 8080 \
        --app erpnext \
        --image "$image" \
        --version "$tag"
    
    # Add hosts entry for .local domain
    if [[ "$sitename" == *.local ]]; then
        if ! grep -q "127.0.0.1.*$sitename" /etc/hosts; then
            log "Adding $sitename to /etc/hosts"
            echo "127.0.0.1 $sitename" | sudo tee -a /etc/hosts > /dev/null
        fi
    fi
        
    log "Deployment completed. Access at: http://$sitename:8080"
    log "Admin credentials in: /home/$USER/$project.env"
}

# Cleanup function
cleanup() {
    local project="${1:-$DEFAULT_PROJECT}"
    log "Cleaning up $project deployment"
    
    if [[ -f "/home/$USER/$project-compose.yml" ]]; then
        # Get sitename from env file for hosts cleanup
        local sitename=""
        if [[ -f "/home/$USER/$project.env" ]]; then
            sitename=$(grep "SITES=" "/home/$USER/$project.env" | cut -d'=' -f2 | tr -d '`')
        fi
        
        docker compose -p "$project" -f "/home/$USER/$project-compose.yml" down -v
        rm -f "/home/$USER/$project-compose.yml" "/home/$USER/$project.env"
        
        # Remove hosts entry if it exists
        if [[ -n "$sitename" && "$sitename" == *.local ]]; then
            if grep -q "127.0.0.1.*$sitename" /etc/hosts; then
                log "Removing $sitename from /etc/hosts"
                sudo sed -i "/127.0.0.1.*$sitename/d" /etc/hosts
            fi
        fi
        
        log "Cleanup completed"
    else
        warn "No deployment found for $project"
    fi
}

# Status function
status() {
    local project="${1:-$DEFAULT_PROJECT}"
    log "Status for $project:"
    
    if [[ -f "/home/$USER/$project-compose.yml" ]]; then
        docker compose -p "$project" -f "/home/$USER/$project-compose.yml" ps
    else
        warn "No deployment found for $project"
    fi
}

# Restart function
restart() {
    local project="${1:-$DEFAULT_PROJECT}"
    log "Restarting $project"
    
    if [[ -f "/home/$USER/$project-compose.yml" ]]; then
        docker compose -p "$project" -f "/home/$USER/$project-compose.yml" restart
        log "Restart completed"
    else
        warn "No deployment found for $project"
    fi
}

# Logs function
logs() {
    local project="${1:-$DEFAULT_PROJECT}"
    local service="${2:-backend}"
    
    if [[ -f "/home/$USER/$project-compose.yml" ]]; then
        docker compose -p "$project" -f "/home/$USER/$project-compose.yml" logs -f "$service"
    else
        warn "No deployment found for $project"
    fi
}

# Docker cleanup function
docker_cleanup() {
    log "Cleaning up all unused Docker resources..."
    docker system prune -a --volumes -f
    log "Docker cleanup completed"
}

# Help function
show_help() {
    cat << EOF
Streamlined Frappe Local Deployment Script

USAGE:
    $0 deploy [project] [sitename] [email] [image] [tag]
    $0 cleanup [project]
    $0 status [project] 
    $0 restart [project]
    $0 logs [project] [service]
    $0 docker-cleanup

COMMANDS:
    deploy         - Deploy new instance (default: mmp-local, mmp.local, admin@mmp.local, frappe/erpnext, v15)
    cleanup        - Remove deployment and cleanup volumes
    status         - Show container status
    restart        - Restart all services
    logs           - Follow logs (default service: backend)
    docker-cleanup - Remove all unused Docker resources

EXAMPLES:
    $0 deploy                                    # Deploy with defaults (latest/dev)
    $0 deploy my-site my.local admin@my.local    # Custom site
    $0 deploy mmp-v15 mmp.local admin@mmp.local frappe/erpnext v15    # ERPNext 15 (stable)
    $0 deploy mmp-v14 mmp.local admin@mmp.local frappe/erpnext v14    # ERPNext 14 (stable)
    $0 deploy mmp-prod prod.local admin@prod.local devburner/mmp-erpnext latest  # Custom MMP image
    $0 status mmp-local                          # Check status
    $0 logs mmp-local frontend                   # Follow frontend logs
    $0 cleanup mmp-local                         # Remove deployment
    $0 docker-cleanup                            # Clean up all Docker resources

VERSION TAGS:
    latest     - v16.0.0-dev (development)
    v15        - ERPNext 15 (stable)
    v14        - ERPNext 14 (stable)
    v15.70.2   - Specific patch version

EOF
}

# Main logic
case "${1:-deploy}" in
    deploy)
        deploy "$2" "$3" "$4" "$5" "$6"
        ;;
    cleanup)
        cleanup "$2"
        ;;
    status)
        status "$2"
        ;;
    restart)
        restart "$2"
        ;;
    logs)
        logs "$2" "$3"
        ;;
    docker-cleanup)
        docker_cleanup
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        error "Unknown command: $1. Use 'help' for usage."
        ;;
esac