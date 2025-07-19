#!/bin/bash

# Frappe Development Environment Setup Script
# Sets up VSCode dev container environments for Frappe development
# VSCode-first approach: prepares environment, then guides user to VSCode workflow
# Designed to work seamlessly with build_mmp_stack.sh and deploy_mmp_local.sh

set -e

# Configuration
DEFAULT_DEV_NAME="frappe-bench"
DEFAULT_FRAPPE_VERSION="version-15"
DEFAULT_SITE_NAME="development.localhost"
DEFAULT_ADMIN_EMAIL="admin@localhost"
DEV_BASE_DIR="../development"
FRAPPE_DOCKER_REPO="https://github.com/frappe/frappe_docker.git"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${GREEN}[$(date '+%H:%M:%S')] $1${NC}"; }
warn() { echo -e "${YELLOW}[$(date '+%H:%M:%S')] WARNING: $1${NC}"; }
error() { echo -e "${RED}[$(date '+%H:%M:%S')] ERROR: $1${NC}"; exit 1; }
info() { echo -e "${BLUE}[$(date '+%H:%M:%S')] INFO: $1${NC}"; }

# Help function
show_help() {
    cat << EOF
Frappe Development Environment Setup Script
VSCode-first approach for Frappe development

USAGE:
    $0 init [dev-name] [options]               # Set up new dev environment
    $0 list                                    # List environments
    $0 info [dev-name]                         # Show environment details
    $0 clean [dev-name]                        # Remove environment

SETUP OPTIONS:
    --frappe-version VER - Frappe version branch (default: version-15)
    --with-erpnext      - Include ERPNext (default: true)
    --with-mmp          - Include MMP Core app
    --site-name NAME    - Site name (default: development.localhost)
    --no-erpnext        - Skip ERPNext installation

EXAMPLES:
    # Standard development setup
    $0 init my-project                         # Creates ../development/my-project/
    
    # MMP development
    $0 init mmp-dev --with-mmp                 # Include MMP Core
    
    # Custom configuration  
    $0 init client-app --site-name client.localhost --frappe-version version-14
    
    # Frappe only (no ERPNext)
    $0 init frappe-only --no-erpnext

DEVELOPMENT WORKFLOW:
    1. Initialize environment:
       $0 init my-project --with-mmp
       
    2. Open in VSCode:
       code ../development/my-project/frappe_docker/
       
    3. In VSCode Command Palette (Ctrl+Shift+P):
       "Dev Containers: Reopen in Container"
       
    4. Develop inside container:
       cd development/frappe-bench
       bench start
       # Access: http://development.localhost:8000
       
    5. Create custom apps:
       bench new-app my_custom_app
       # Push to GitHub when ready
       
    6. Build production image:
       ./build_mmp_stack.sh build --app github.com/user/my_custom_app:main
       
    7. Deploy for testing:
       ./deploy_mmp_local.sh deploy --ssl

TIPS:
    - Install "Dev Containers" VSCode extension first
    - Use Git to version control your custom apps
    - Build script can include apps from GitHub repos
    - Keep development and build processes separate for best practices

EOF
}

# Check requirements
check_requirements() {
    command -v docker >/dev/null || error "Docker is required but not installed"
    command -v git >/dev/null || error "Git is required but not installed"
    
    # Check if user is in docker group
    if ! groups | grep -q docker; then
        warn "User not in docker group. You may need to use sudo or logout/login"
    fi
    
    # Check Docker is running
    if ! docker info >/dev/null 2>&1; then
        error "Docker is not running. Please start Docker first."
    fi
    
    # Check memory allocation
    local docker_memory=$(docker system info --format '{{.MemTotal}}' 2>/dev/null || echo "0")
    if [[ $docker_memory -lt 4000000000 ]]; then
        warn "Docker has less than 4GB memory allocated. Development may be slow."
        warn "Consider increasing Docker memory allocation in Docker Desktop settings."
    fi
}

# Create development base directory
setup_dev_directory() {
    if [[ ! -d "$DEV_BASE_DIR" ]]; then
        log "Creating development directory: $DEV_BASE_DIR"
        mkdir -p "$DEV_BASE_DIR"
    fi
}

# Get frappe_docker if needed
setup_frappe_docker() {
    local dev_name="$1"
    local dev_path="$DEV_BASE_DIR/$dev_name"
    
    if [[ ! -d "$dev_path/frappe_docker" ]]; then
        log "Downloading frappe_docker repository..."
        cd "$DEV_BASE_DIR"
        git clone --depth 1 "$FRAPPE_DOCKER_REPO" "$dev_name/frappe_docker"
        cd - > /dev/null
    else
        log "Frappe docker repository already exists"
    fi
}

# Set up devcontainer configuration
setup_devcontainer() {
    local dev_name="$1"
    local dev_path="$DEV_BASE_DIR/$dev_name"
    local frappe_docker_path="$dev_path/frappe_docker"
    
    log "Setting up devcontainer configuration..."
    
    # Copy devcontainer example
    if [[ ! -d "$frappe_docker_path/.devcontainer" ]]; then
        cp -r "$frappe_docker_path/devcontainer-example" "$frappe_docker_path/.devcontainer"
        log "Devcontainer configuration copied"
    fi
    
    # Copy VSCode configuration
    if [[ ! -d "$frappe_docker_path/development/.vscode" ]]; then
        mkdir -p "$frappe_docker_path/development"
        cp -r "$frappe_docker_path/development/vscode-example" "$frappe_docker_path/development/.vscode"
        log "VSCode configuration copied"
    fi
}

# Create setup instructions file
create_setup_instructions() {
    local dev_name="$1"
    local frappe_version="$2"
    local site_name="$3"
    local with_erpnext="$4"
    local with_mmp="$5"
    local dev_path="$DEV_BASE_DIR/$dev_name"
    
    cat > "$dev_path/SETUP-INSTRUCTIONS.md" << EOF
# Development Environment: $dev_name

## Quick Start

1. **Open in VSCode**:
   \`\`\`bash
   code $dev_path/frappe_docker/
   \`\`\`

2. **Reopen in Container**:
   - Press \`Ctrl+Shift+P\` (Cmd+Shift+P on macOS)
   - Type: "Dev Containers: Reopen in Container"
   - Wait for container to build (first time takes 5-10 minutes)

3. **Initialize Bench** (inside container terminal):
   \`\`\`bash
   cd development/
   bench init --skip-redis-config-generation --frappe-branch $frappe_version frappe-bench
   cd frappe-bench
   
   # Configure hosts
   bench set-config -g db_host mariadb
   bench set-config -g redis_cache redis://redis-cache:6379
   bench set-config -g redis_queue redis://redis-queue:6379
   bench set-config -g redis_socketio redis://redis-queue:6379
   
   # Edit Procfile for Redis containers
   sed -i '/redis/d' ./Procfile
   \`\`\`

4. **Install Apps** (if desired):
   \`\`\`bash$(if [[ "$with_erpnext" == "true" ]]; then echo "
   # Install ERPNext
   bench get-app --branch $frappe_version erpnext"; fi)$(if [[ "$with_mmp" == "true" ]]; then echo "
   
   # Install MMP Core
   bench get-app --branch develop https://github.com/christophdanger/mmp_core.git"; fi)
   \`\`\`

5. **Create Site**:
   \`\`\`bash
   bench new-site --no-mariadb-socket --admin-password admin $site_name$(if [[ "$with_erpnext" == "true" ]]; then echo "
   bench --site $site_name install-app erpnext"; fi)$(if [[ "$with_mmp" == "true" ]]; then echo "
   bench --site $site_name install-app mmp_core"; fi)
   
   # Enable developer mode
   bench --site $site_name set-config developer_mode 1
   bench --site $site_name clear-cache
   \`\`\`

6. **Start Development**:
   \`\`\`bash
   bench start
   \`\`\`
   
   Access: [http://$site_name:8000](http://$site_name:8000)
   Login: Administrator / admin

## Development Workflow

### Creating Custom Apps
\`\`\`bash
# Inside the container
bench new-app my_custom_app
bench --site $site_name install-app my_custom_app
\`\`\`

### Building Production Image
When ready to deploy your custom app:

1. **Push to GitHub**:
   \`\`\`bash
   cd apps/my_custom_app
   git init && git add . && git commit -m "Initial commit"
   git remote add origin https://github.com/username/my_custom_app.git
   git push -u origin main
   \`\`\`

2. **Build Docker Image**:
   \`\`\`bash
   # From xpress/deploy/ directory
   ./build_mmp_stack.sh build --app github.com/username/my_custom_app:main --push
   \`\`\`

3. **Deploy for Testing**:
   \`\`\`bash
   ./deploy_mmp_local.sh deploy --ssl
   \`\`\`

## Environment Management

- **List environments**: \`./dev_mmp_stack.sh list\`
- **Environment info**: \`./dev_mmp_stack.sh info $dev_name\`
- **Clean up**: \`./dev_mmp_stack.sh clean $dev_name\`

## Prerequisites

- VSCode with "Dev Containers" extension
- Docker with at least 4GB memory allocation
- Git configured

EOF

    log "Setup instructions created: $dev_path/SETUP-INSTRUCTIONS.md"
}

# Generate development info file
generate_dev_info() {
    local dev_name="$1"
    local site_name="$2"
    local admin_email="$3"
    local with_erpnext="$4"
    local with_mmp="$5"
    local dev_path="$DEV_BASE_DIR/$dev_name"
    
    cat > "$dev_path/dev-info.txt" << EOF
# Development Environment: $dev_name
# Generated: $(date)

=== QUICK ACCESS ===
1. Open VSCode: code $dev_path/frappe_docker/
2. Reopen in container: Ctrl+Shift+P -> "Dev Containers: Reopen in Container"
3. Read setup guide: cat $dev_path/SETUP-INSTRUCTIONS.md

=== CONFIGURATION ===
Environment Path: $dev_path/frappe_docker/
Site Name: $site_name
Frappe Version: version-15
Include ERPNext: $with_erpnext
Include MMP Core: $with_mmp

=== PRODUCTION WORKFLOW ===
1. Develop apps in VSCode dev container
2. Push custom apps to GitHub
3. Build: ./build_mmp_stack.sh build --app github.com/user/app:main
4. Deploy: ./deploy_mmp_local.sh deploy --ssl

EOF
    
    log "Development info saved to: $dev_path/dev-info.txt"
}

# Initialize development environment
init_environment() {
    local dev_name="${1:-$DEFAULT_DEV_NAME}"
    local frappe_version="$DEFAULT_FRAPPE_VERSION"
    local site_name="$DEFAULT_SITE_NAME"
    local admin_email="$DEFAULT_ADMIN_EMAIL"
    local with_erpnext="true"
    local with_mmp="false"
    
    # Parse arguments
    shift # Remove command
    while [[ $# -gt 0 ]]; do
        case $1 in
            --frappe-version)
                frappe_version="$2"
                shift 2
                ;;
            --with-erpnext)
                with_erpnext="true"
                shift
                ;;
            --with-mmp)
                with_mmp="true"
                shift
                ;;
            --site-name)
                site_name="$2"
                shift 2
                ;;
            --no-erpnext)
                with_erpnext="false"
                shift
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                # If it doesn't start with --, treat as dev_name
                if [[ ! "$1" =~ ^-- ]]; then
                    dev_name="$1"
                else
                    warn "Unknown option: $1"
                fi
                shift
                ;;
        esac
    done
    
    local dev_path="$DEV_BASE_DIR/$dev_name"
    
    log "Initializing development environment: $dev_name"
    info "Configuration:"
    info "  Name: $dev_name"
    info "  Path: $dev_path"
    info "  Frappe Version: $frappe_version"
    info "  Site Name: $site_name"
    info "  Include ERPNext: $with_erpnext"
    info "  Include MMP Core: $with_mmp"
    
    # Check if environment already exists
    if [[ -d "$dev_path" ]]; then
        warn "Development environment already exists: $dev_path"
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log "Aborted"
            exit 0
        fi
    fi
    
    check_requirements
    setup_dev_directory
    setup_frappe_docker "$dev_name"
    setup_devcontainer "$dev_name"
    create_setup_instructions "$dev_name" "$frappe_version" "$site_name" "$with_erpnext" "$with_mmp"
    generate_dev_info "$dev_name" "$site_name" "$admin_email" "$with_erpnext" "$with_mmp"
    
    log "Development environment '$dev_name' set up successfully!"
    log ""
    info "NEXT STEPS:"
    info "1. Open in VSCode:"
    info "   code $dev_path/frappe_docker/"
    info ""
    info "2. In VSCode (Ctrl+Shift+P):"
    info "   'Dev Containers: Reopen in Container'"
    info ""
    info "3. Follow setup instructions:"
    info "   cat $dev_path/SETUP-INSTRUCTIONS.md"
    log ""
    warn "This script only PREPARES the environment. Use VSCode for actual development."
}


# Show environment information
show_info() {
    local dev_name="${1:-$DEFAULT_DEV_NAME}"
    local dev_path="$DEV_BASE_DIR/$dev_name"
    
    if [[ ! -d "$dev_path" ]]; then
        error "Development environment not found: $dev_path"
    fi
    
    if [[ -f "$dev_path/dev-info.txt" ]]; then
        cat "$dev_path/dev-info.txt"
    else
        log "Development environment: $dev_name"
        log "Path: $dev_path"
        warn "Info file not found. Environment may be incomplete."
    fi
}

# Clean up development environment
clean_environment() {
    local dev_name="${1:-$DEFAULT_DEV_NAME}"
    local dev_path="$DEV_BASE_DIR/$dev_name"
    
    if [[ ! -d "$dev_path" ]]; then
        warn "Development environment not found: $dev_path"
        return
    fi
    
    log "Cleaning up development environment: $dev_name"
    
    # Stop any running containers first
    if [[ -d "$dev_path/frappe_docker" ]]; then
        cd "$dev_path/frappe_docker"
        docker compose -f .devcontainer/docker-compose.yml down -v 2>/dev/null || true
        cd - > /dev/null
    fi
    
    # Remove directory
    rm -rf "$dev_path"
    
    log "Development environment '$dev_name' removed"
    warn "Remember to close any VSCode windows for this environment"
}

# List all development environments
list_environments() {
    log "Development environments:"
    
    if [[ ! -d "$DEV_BASE_DIR" ]]; then
        info "No development directory found"
        info "Create one with: $0 init my-dev-env"
        return
    fi
    
    local found=false
    for dir in "$DEV_BASE_DIR"/*; do
        if [[ -d "$dir" ]]; then
            local name=$(basename "$dir")
            info "  $name - Ready for VSCode"
            found=true
        fi
    done
    
    if [[ "$found" == false ]]; then
        info "No development environments found"
        info "Create one with: $0 init my-dev-env"
    fi
}

# Main logic
case "${1:-help}" in
    init)
        shift
        init_environment "$@"
        ;;
    info)
        show_info "$2"
        ;;
    clean)
        clean_environment "$2"
        ;;
    list)
        list_environments
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        error "Unknown command: $1. Use 'help' for usage."
        ;;
esac