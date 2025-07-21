#!/bin/bash
# Auto-generated Frappe development setup
# This gets customized based on your dev_mmp_stack.sh choices

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${GREEN}[$(date '+%H:%M:%S')] $1${NC}"; }
warn() { echo -e "${YELLOW}[$(date '+%H:%M:%S')] WARNING: $1${NC}"; }
info() { echo -e "${BLUE}[$(date '+%H:%M:%S')] INFO: $1${NC}"; }

log "Starting automated Frappe development setup..."
log "Configuration: Frappe {{FRAPPE_VERSION}}{{ERPNEXT_FLAG}}{{MMP_FLAG}}"

if [[ -d "/workspace/development/frappe-bench" ]]; then
    warn "Bench already exists. Remove it first: rm -rf /workspace/development/frappe-bench"
    exit 1
fi

cd /workspace/development

log "Initializing Frappe bench..."
bench init --skip-redis-config-generation --frappe-branch {{FRAPPE_VERSION}} frappe-bench
cd frappe-bench

log "Configuring database and Redis connections..."
bench set-config -g db_host mariadb
bench set-config -g redis_cache redis://redis-cache:6379
bench set-config -g redis_queue redis://redis-queue:6379
bench set-config -g redis_socketio redis://redis-queue:6379
sed -i '/redis/d' ./Procfile

{{ERPNEXT_INSTALL}}
{{MMP_INSTALL}}

log "Creating site: {{SITE_NAME}}"
bench new-site --no-mariadb-socket --admin-password admin {{SITE_NAME}}

{{ERPNEXT_SITE_INSTALL}}
{{MMP_SITE_INSTALL}}

log "Enabling developer mode..."
bench --site {{SITE_NAME}} set-config developer_mode 1
bench --site {{SITE_NAME}} clear-cache

log "Setup complete! 🎉"
info "Start development: bench start"
info "Access: http://{{SITE_NAME}}:8000"
info "Login: Administrator / admin"