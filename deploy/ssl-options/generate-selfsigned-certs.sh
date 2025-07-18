#!/bin/bash
# Generate self-signed certificates for local development

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log() { echo -e "${GREEN}[$(date '+%H:%M:%S')] $1${NC}"; }
warn() { echo -e "${YELLOW}[$(date '+%H:%M:%S')] WARNING: $1${NC}"; }
error() { echo -e "${RED}[$(date '+%H:%M:%S')] ERROR: $1${NC}"; exit 1; }

# Generate self-signed certificates
generate_certificates() {
    local domain="${1:-mmp.local}"
    local project="${2:-mmp-local}"
    
    log "Generating self-signed certificates for $domain..."
    
    # Create ssl-certs directory
    mkdir -p "./ssl-certs"
    cd "./ssl-certs"
    
    # Create certificate configuration
    cat > cert.conf << EOF
[req]
distinguished_name = req_distinguished_name
req_extensions = v3_req
prompt = no

[req_distinguished_name]
C = US
ST = Local
L = Local
O = Local Development
OU = IT Department
CN = $domain

[v3_req]
keyUsage = keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = $domain
DNS.2 = *.$domain
DNS.3 = localhost
DNS.4 = grafana.$domain
DNS.5 = traefik.$domain
IP.1 = 127.0.0.1
IP.2 = ::1
EOF
    
    # Generate private key
    openssl genrsa -out key.pem 2048
    
    # Generate certificate
    openssl req -new -x509 -key key.pem -out cert.pem -days 365 -config cert.conf -extensions v3_req
    
    # Set proper permissions
    chmod 600 key.pem
    chmod 644 cert.pem
    
    # Clean up
    rm cert.conf
    
    log "Certificates generated successfully:"
    log "  - cert.pem (certificate) - valid for 365 days"
    log "  - key.pem (private key)"
    log "  - Valid for: $domain, *.$domain, localhost, grafana.$domain, traefik.$domain"
    
    cd ..
}

# Update /etc/hosts for local domains
update_hosts() {
    local domain="${1:-mmp.local}"
    
    local domains_to_add=(
        "$domain"
        "grafana.$domain"
        "traefik.$domain"
    )
    
    for d in "${domains_to_add[@]}"; do
        if ! grep -q "127.0.0.1.*$d" /etc/hosts; then
            log "Adding $d to /etc/hosts..."
            echo "127.0.0.1 $d" | sudo tee -a /etc/hosts > /dev/null
        else
            log "$d already in /etc/hosts"
        fi
    done
}

# Display certificate information
show_cert_info() {
    local domain="${1:-mmp.local}"
    
    if [[ -f "./ssl-certs/cert.pem" ]]; then
        log "Certificate information:"
        openssl x509 -in "./ssl-certs/cert.pem" -text -noout | grep -A 5 "Subject Alternative Name"
        
        log "Certificate expires:"
        openssl x509 -in "./ssl-certs/cert.pem" -enddate -noout
    fi
}

# Main function
main() {
    local domain="${1:-mmp.local}"
    local project="${2:-mmp-local}"
    
    log "Generating self-signed certificates for local development"
    log "Domain: $domain"
    log "Project: $project"
    
    generate_certificates "$domain" "$project"
    update_hosts "$domain"
    show_cert_info "$domain"
    
    log "Setup complete!"
    log ""
    log "Next steps:"
    log "1. Deploy with SSL: ./deploy_mmp_local.sh add-ssl $project"
    log "2. Access your site at https://$domain"
    log "3. Accept the self-signed certificate in your browser"
    log ""
    warn "Browser will show security warning for self-signed certificates"
    warn "This is normal for local development - click 'Advanced' and 'Accept Risk'"
}

# Show help
show_help() {
    cat << EOF
Self-Signed Certificate Generator for Local Development

USAGE:
    $0 [domain] [project]

EXAMPLES:
    $0                                    # Use defaults (mmp.local, mmp-local)
    $0 mysite.local myproject            # Custom domain and project
    $0 app.local                         # Custom domain, default project

This script will:
1. Generate self-signed SSL certificates using OpenSSL
2. Configure certificates for multiple subdomains
3. Update /etc/hosts for local domains
4. Set proper file permissions

The certificates will be valid for 365 days and include:
- Main domain (e.g., mmp.local)
- Wildcard subdomain (e.g., *.mmp.local)
- Grafana subdomain (e.g., grafana.mmp.local)
- Traefik subdomain (e.g., traefik.mmp.local)
- localhost and IP addresses

EOF
}

# Handle command line arguments
case "${1:-setup}" in
    help|--help|-h)
        show_help
        ;;
    *)
        main "$1" "$2"
        ;;
esac