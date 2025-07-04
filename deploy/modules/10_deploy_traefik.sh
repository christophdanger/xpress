#!/usr/bin/env bash

deploy_traefik() {
  echo "### Deploying Traefik..."

  # Ensure acme.json file exists and has correct permissions for Traefik
  local ACME_JSON_PATH="$GITOPS_DIR/traefik/acme.json"
  if [ ! -f "$ACME_JSON_PATH" ]; then
    echo "Creating acme.json file for Traefik..."
    mkdir -p "$(dirname "$ACME_JSON_PATH")"
    touch "$ACME_JSON_PATH"
    chmod 600 "$ACME_JSON_PATH"
  else
    echo "acme.json file already exists. Skipping creation."
  fi

  # Configure and deploy Traefik
  local TRAEFIK_ENV="$GITOPS_DIR/traefik.env"
  if [ ! -f "$TRAEFIK_ENV" ]; then
    echo "Configuring Traefik environment..."
    cat > "$TRAEFIK_ENV" <<EOF
TRAEFIK_DOMAIN=${TRAEFIK_DOMAIN}
EMAIL=${TRAEFIK_EMAIL}
HASHED_PASSWORD=$(openssl passwd -apr1 "${TRAEFIK_PASSWORD}" | sed -e 's/\$/\$\$/g')
EOF
  fi

  docker compose \
    --project-name traefik \
    --env-file "$TRAEFIK_ENV" \
    -f "$FRAPPE_DOCKER_DIR/overrides/compose.traefik.yaml" \
    -f "$FRAPPE_DOCKER_DIR/overrides/compose.traefik-ssl.yaml" \
    up -d
  echo "### Traefik Deployed."
}