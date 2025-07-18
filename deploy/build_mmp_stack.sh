#!/bin/bash

# Frappe Stack Docker Build Script
# Builds custom Docker images with Frappe Framework + your apps
# Smart defaults with full flexibility for any stack configuration
# Designed for both local development and CI/CD automation

set -e

# Configuration
DEFAULT_REGISTRY="devburner"
DEFAULT_IMAGE_NAME="frappe-erpnext"
DEFAULT_FRAPPE_VERSION="version-15"
DEFAULT_MMP_BRANCH="develop"
DEFAULT_BUILD_CONTEXT="./frappe_docker"

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
Frappe Stack Docker Build Script

USAGE:
    $0 build [options]
    $0 setup
    $0 clean

COMMANDS:
    build          - Build Docker image with Frappe stack
    setup          - Set up build environment (downloads frappe_docker)
    clean          - Clean up build artifacts and temp files

BUILD OPTIONS:
    --push         - Push image to registry after build
    --local        - Build for local use only (no registry push)
    --tag TAG      - Custom tag for image (default: latest)
    --registry REG - Registry to use (default: devburner)
    --frappe-version VER - Frappe version branch (default: version-15)
    
    --mmp          - Add MMP Core to the build (for MMP developers)
    --mmp-branch BRANCH - MMP Core branch (default: develop)
    --app URL:BRANCH - Add custom app (can be used multiple times)
    --config FILE  - Use apps config file (JSON format)
    --base-only    - Build Frappe only (no ERPNext)

EXAMPLES:
    # Standard builds (most common)
    $0 build                                    # Frappe + ERPNext (default)
    $0 build --push                             # Build and push to registry
    $0 build --tag stable --push               # Tagged stable build
    
    # MMP developers
    $0 build --mmp                              # Frappe + ERPNext + MMP Core
    $0 build --mmp --mmp-branch main --tag production
    
    # Custom apps
    $0 build --app github.com/user/hrms:v15 --tag hrms-stack
    $0 build --app github.com/user/app1:main --app github.com/user/app2:develop
    
    # Advanced usage
    $0 build --config ./my-apps.json --tag client-stack
    $0 build --base-only --tag frappe-only     # Just Frappe framework
    $0 build --registry ghcr.io/username --push # GitHub Container Registry

ORCHESTRATION:
    # Standard developer workflow
    $0 setup                                    # One-time setup
    $0 build --push                            # Build and push standard stack
    ./deploy_mmp_local.sh deploy --ssl         # Deploy with new image
    
    # MMP developer workflow  
    $0 build --mmp --push                      # Build and push MMP stack
    ./deploy_mmp_local.sh deploy mmp-dev mmp.local admin@mmp.local devburner/frappe-erpnext latest --ssl

EOF
}

# Check requirements
check_requirements() {
    command -v docker >/dev/null || error "Docker is required but not installed"
    command -v base64 >/dev/null || error "base64 is required but not installed"
    command -v git >/dev/null || error "git is required but not installed"
    
    # Check if user is in docker group
    if ! groups | grep -q docker; then
        warn "User not in docker group. You may need to use sudo or logout/login"
    fi
}

# Setup build environment
setup_build_env() {
    log "Setting up build environment..."
    
    # Download frappe_docker if not exists
    if [[ ! -d "./frappe_docker" ]]; then
        log "Downloading frappe_docker repository..."
        git clone --depth 1 https://github.com/frappe/frappe_docker.git ./frappe_docker
    else
        log "Frappe docker repository already exists"
        # Update to latest
        cd ./frappe_docker
        git pull origin main || warn "Could not update frappe_docker (continuing with existing version)"
        cd ..
    fi
    
    # Verify build context exists
    if [[ ! -f "./frappe_docker/images/layered/Containerfile" ]]; then
        error "Build context not found. Expected: ./frappe_docker/images/layered/Containerfile"
    fi
    
    log "Build environment ready"
}

# Generate apps.json configuration
generate_apps_config() {
    local frappe_version="$1"
    local include_erpnext="$2"
    local include_mmp="$3"
    local mmp_branch="$4"
    local custom_apps="$5"
    local config_file="$6"
    
    log "Generating apps.json configuration..."
    info "Frappe version: $frappe_version"
    
    # If config file provided, use it directly
    if [[ -n "$config_file" ]]; then
        if [[ ! -f "$config_file" ]]; then
            error "Config file not found: $config_file"
        fi
        cp "$config_file" "/tmp/mmp-apps.json"
        log "Using custom config file: $config_file"
        return
    fi
    
    # Start building apps array
    local apps_json="["
    local first_app=true
    
    # Add ERPNext if requested (default behavior)
    if [[ "$include_erpnext" == "true" ]]; then
        if [[ "$first_app" == "false" ]]; then
            apps_json+=","
        fi
        apps_json+="
  {
    \"url\": \"https://github.com/frappe/erpnext.git\",
    \"branch\": \"$frappe_version\"
  }"
        first_app=false
        info "  - ERPNext ($frappe_version)"
    fi
    
    # Add MMP Core if requested
    if [[ "$include_mmp" == "true" ]]; then
        if [[ "$first_app" == "false" ]]; then
            apps_json+=","
        fi
        apps_json+="
  {
    \"url\": \"https://github.com/christophdanger/mmp_core.git\",
    \"branch\": \"$mmp_branch\"
  }"
        first_app=false
        info "  - MMP Core ($mmp_branch)"
    fi
    
    # Add custom apps
    if [[ -n "$custom_apps" ]]; then
        IFS=',' read -ra APPS <<< "$custom_apps"
        for app in "${APPS[@]}"; do
            if [[ "$first_app" == "false" ]]; then
                apps_json+=","
            fi
            
            # Parse app format: url:branch
            local app_url="${app%:*}"
            local app_branch="${app#*:}"
            
            # Default to main if no branch specified
            if [[ "$app_url" == "$app_branch" ]]; then
                app_branch="main"
            fi
            
            # Add github.com if not a full URL
            if [[ ! "$app_url" =~ ^https?:// ]]; then
                app_url="https://github.com/$app_url.git"
            fi
            
            apps_json+="
  {
    \"url\": \"$app_url\",
    \"branch\": \"$app_branch\"
  }"
            first_app=false
            info "  - Custom app: $app_url ($app_branch)"
        done
    fi
    
    # Close JSON array
    apps_json+="
]"
    
    # Write to temp file
    echo "$apps_json" > "/tmp/mmp-apps.json"
    
    log "Apps configuration generated"
    
    # Show warning if no apps were added
    if [[ "$first_app" == "true" ]]; then
        warn "No apps specified - building Frappe framework only"
    fi
}

# Build Docker image
build_image() {
    local registry="$1"
    local image_name="$2"
    local tag="$3"
    local frappe_version="$4"
    local include_erpnext="$5"
    local include_mmp="$6"
    local mmp_branch="$7"
    local custom_apps="$8"
    local config_file="$9"
    local build_context="${10:-$DEFAULT_BUILD_CONTEXT}"
    
    local full_image_name="$registry/$image_name:$tag"
    
    log "Building Docker image: $full_image_name"
    
    # Generate apps configuration
    generate_apps_config "$frappe_version" "$include_erpnext" "$include_mmp" "$mmp_branch" "$custom_apps" "$config_file"
    
    # Create base64 encoded apps.json
    local apps_json_base64
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        apps_json_base64=$(base64 -i /tmp/mmp-apps.json)
    else
        # Linux
        apps_json_base64=$(base64 -w 0 /tmp/mmp-apps.json)
    fi
    
    log "Base64 encoded apps.json: ${apps_json_base64:0:50}..."
    
    # Build the image
    info "Starting Docker build (this may take 10-20 minutes)..."
    
    docker build \
        --build-arg=FRAPPE_PATH=https://github.com/frappe/frappe \
        --build-arg=FRAPPE_BRANCH="$frappe_version" \
        --build-arg=APPS_JSON_BASE64="$apps_json_base64" \
        --tag="$full_image_name" \
        --file="$build_context/images/layered/Containerfile" \
        --progress=plain \
        "$build_context"
    
    log "Docker image built successfully: $full_image_name"
    
    # Verify the build
    info "Verifying image..."
    docker images | grep "$registry/$image_name" | grep "$tag" || error "Image not found after build"
    
    # Clean up temp files
    rm -f /tmp/mmp-apps.json
    
    echo "$full_image_name"
}

# Push image to registry
push_image() {
    local image_name="$1"
    
    log "Pushing image to registry: $image_name"
    
    # Check if logged in (basic check)
    if ! docker info | grep -q "Username:"; then
        warn "You may need to login to Docker registry first:"
        warn "  docker login                    # For Docker Hub"
        warn "  docker login ghcr.io           # For GitHub Container Registry"
    fi
    
    docker push "$image_name" || error "Failed to push image to registry"
    
    log "Image pushed successfully: $image_name"
}

# Generate deployment-ready info
generate_deployment_info() {
    local image_name="$1"
    local include_erpnext="$2"
    local include_mmp="$3"
    local mmp_branch="$4"
    local frappe_version="$5"
    
    cat > "/tmp/frappe-build-info.txt" << EOF
# Frappe Stack Build Information
# Generated: $(date)

IMAGE: $image_name
FRAPPE_VERSION: $frappe_version
INCLUDES_ERPNEXT: $include_erpnext
INCLUDES_MMP: $include_mmp
MMP_BRANCH: $mmp_branch

# Deploy with this image:
./deploy_mmp_local.sh deploy custom-stack custom.local admin@custom.local "$image_name" latest --ssl

# For production deployment:
# Push to your registry and update deployment configurations
EOF
    
    log "Build info saved to: /tmp/frappe-build-info.txt"
    info "Quick deploy command:"
    info "  ./deploy_mmp_local.sh deploy custom-stack custom.local admin@custom.local '$image_name' latest --ssl"
}

# Main build function
build() {
    local push_image_flag=false
    local registry="$DEFAULT_REGISTRY"
    local image_name="$DEFAULT_IMAGE_NAME"
    local tag="latest"
    local frappe_version="$DEFAULT_FRAPPE_VERSION"
    local include_erpnext="true"  # Default: include ERPNext
    local include_mmp="false"     # Default: no MMP Core
    local mmp_branch="$DEFAULT_MMP_BRANCH"
    local custom_apps=""
    local config_file=""
    local build_context="$DEFAULT_BUILD_CONTEXT"
    
    # Parse build arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --push)
                push_image_flag=true
                shift
                ;;
            --local)
                push_image_flag=false
                shift
                ;;
            --tag)
                tag="$2"
                shift 2
                ;;
            --registry)
                registry="$2"
                shift 2
                ;;
            --frappe-version)
                frappe_version="$2"
                shift 2
                ;;
            --mmp)
                include_mmp="true"
                shift
                ;;
            --mmp-branch)
                mmp_branch="$2"
                shift 2
                ;;
            --base-only)
                include_erpnext="false"
                shift
                ;;
            --app)
                if [[ -n "$custom_apps" ]]; then
                    custom_apps="$custom_apps,$2"
                else
                    custom_apps="$2"
                fi
                shift 2
                ;;
            --config)
                config_file="$2"
                shift 2
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                warn "Unknown option: $1"
                shift
                ;;
        esac
    done
    
    # Auto-adjust image name based on what's included
    if [[ "$include_mmp" == "true" ]]; then
        image_name="mmp-erpnext"
    elif [[ "$include_erpnext" == "false" ]]; then
        image_name="frappe-base"
    fi
    
    log "Starting Frappe Stack build..."
    info "Configuration:"
    info "  Registry: $registry"
    info "  Image: $image_name:$tag"
    info "  Frappe Version: $frappe_version"
    info "  Include ERPNext: $include_erpnext"
    info "  Include MMP Core: $include_mmp"
    if [[ "$include_mmp" == "true" ]]; then
        info "  MMP Branch: $mmp_branch"
    fi
    if [[ -n "$custom_apps" ]]; then
        info "  Custom Apps: $custom_apps"
    fi
    if [[ -n "$config_file" ]]; then
        info "  Config File: $config_file"
    fi
    info "  Push to registry: $push_image_flag"
    
    check_requirements
    setup_build_env
    
    # Build the image
    local built_image
    built_image=$(build_image "$registry" "$image_name" "$tag" "$frappe_version" "$include_erpnext" "$include_mmp" "$mmp_branch" "$custom_apps" "$config_file" "$build_context")
    
    # Push if requested
    if [[ "$push_image_flag" == true ]]; then
        push_image "$built_image"
    fi
    
    # Generate deployment info
    generate_deployment_info "$built_image" "$include_erpnext" "$include_mmp" "$mmp_branch" "$frappe_version"
    
    log "Build completed successfully!"
    log "Image: $built_image"
    
    if [[ "$push_image_flag" == true ]]; then
        log "Image pushed to registry and ready for deployment"
    else
        log "Image built locally. Use --push to push to registry"
    fi
}

# Clean up build artifacts
clean() {
    log "Cleaning up build artifacts..."
    
    # Clean up temp files
    rm -f /tmp/mmp-apps.json /tmp/frappe-build-info.txt
    
    # Remove dangling images
    docker image prune -f
    
    log "Cleanup completed"
}

# Main logic
case "${1:-build}" in
    build)
        shift
        build "$@"
        ;;
    setup)
        check_requirements
        setup_build_env
        ;;
    clean)
        clean
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        error "Unknown command: $1. Use 'help' for usage."
        ;;
esac