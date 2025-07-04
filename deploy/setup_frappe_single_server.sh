#!/usr/bin/env bash
# filepath: /Users/cmsmith/src/mmp-deployment/setup_frappe_single_server_modified.sh
# setup_frappe_single_server.sh
# Automates the Frappe Docker single-server example with idempotency improvements

set -euo pipefail

#######  Configuration  #######
WORKDIR="/opt/frappe"
GITOPS_DIR="${WORKDIR}/gitops"
FRAPPE_DOCKER_DIR="${WORKDIR}/frappe_docker"

TRAEFIK_DOMAIN="traefik-erpnext.devburner.io"
TRAEFIK_EMAIL="cmsmitty84+traefik-mmp@gmail.com"
TRAEFIK_PASSWORD="##################"
MARIADB_PASSWORD="##################"
BENCH1_NAME="erpnext-one"
BENCH1_SITES=("erp.devburner.io")

########################################

# Function to check if a command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Ensure directories exist
if [ ! -d "$WORKDIR" ]; then
  echo "Creating working directory: $WORKDIR"
  sudo mkdir -p "$WORKDIR"
  sudo chown -R "$USER:$USER" "$WORKDIR"
fi

if [ ! -d "$GITOPS_DIR" ]; then
  echo "Creating gitops directory: $GITOPS_DIR"
  mkdir -p "$GITOPS_DIR"
fi

if [ ! -d "$FRAPPE_DOCKER_DIR" ]; then
  echo "Cloning frappe_docker repository..."
  git clone https://github.com/christophdanger/devburner-frappe_docker.git "$FRAPPE_DOCKER_DIR"
else
  echo "frappe_docker repository already exists. Skipping clone."
fi

# Install Docker if not already installed
if ! command_exists docker; then
  echo "Installing Docker..."
  curl -fsSL https://get.docker.com | bash
  sudo usermod -aG docker "$USER"
else
  echo "Docker is already installed. Skipping installation."
fi

# Install Docker Compose v2 plugin if not already installed
DOCKER_COMPOSE_PATH="${WORKDIR}/.docker/cli-plugins/docker-compose"
if [ ! -f "$DOCKER_COMPOSE_PATH" ]; then
  echo "Installing Docker Compose v2 plugin..."
  mkdir -p "$(dirname "$DOCKER_COMPOSE_PATH")"
  curl -SL https://github.com/docker/compose/releases/download/v2.2.3/docker-compose-linux-x86_64 \
       -o "$DOCKER_COMPOSE_PATH"
  chmod +x "$DOCKER_COMPOSE_PATH"
else
  echo "Docker Compose v2 plugin is already installed. Skipping installation."
fi

# Ensure acme.json file exists and has correct permissions for Traefik
ACME_JSON_PATH="$GITOPS_DIR/traefik/acme.json"
if [ ! -f "$ACME_JSON_PATH" ]; then
  echo "Creating acme.json file for Traefik..."
  mkdir -p "$(dirname "$ACME_JSON_PATH")"
  touch "$ACME_JSON_PATH"
  chmod 600 "$ACME_JSON_PATH"
else
  echo "acme.json file already exists. Skipping creation."
fi

# Configure and deploy Traefik
TRAEFIK_ENV="$GITOPS_DIR/traefik.env"
if [ ! -f "$TRAEFIK_ENV" ]; then
  echo "Configuring Traefik environment..."
  cat > "$TRAEFIK_ENV" <<EOF
TRAEFIK_DOMAIN=${TRAEFIK_DOMAIN}
EMAIL=${TRAEFIK_EMAIL}
HASHED_PASSWORD=$(openssl passwd -apr1 "${TRAEFIK_PASSWORD}" | sed -e 's/\$/\$\$/g')
EOF
fi

echo "Deploying Traefik..."
docker compose \
  --project-name traefik \
  --env-file "$TRAEFIK_ENV" \
  -f "$FRAPPE_DOCKER_DIR/overrides/compose.traefik.yaml" \
  -f "$FRAPPE_DOCKER_DIR/overrides/compose.traefik-ssl.yaml" \
  up -d

# Configure and deploy MariaDB
MARIADB_ENV="$GITOPS_DIR/mariadb.env"
if [ ! -f "$MARIADB_ENV" ]; then
  echo "Configuring MariaDB environment..."
  echo "DB_PASSWORD=${MARIADB_PASSWORD}" > "$MARIADB_ENV"
fi

echo "Deploying MariaDB..."
docker compose \
  --project-name mariadb \
  --env-file "$MARIADB_ENV" \
  -f "$FRAPPE_DOCKER_DIR/overrides/compose.mariadb-shared.yaml" \
  up -d

# Set up first bench
BENCH1_ENV="$GITOPS_DIR/${BENCH1_NAME}.env"
if [ ! -f "$BENCH1_ENV" ]; then
  echo "Configuring first bench (${BENCH1_NAME})..."
  cp "$FRAPPE_DOCKER_DIR/example.env" "$BENCH1_ENV"
  sed -i \
    -e "s/DB_PASSWORD=123/DB_PASSWORD=${MARIADB_PASSWORD}/" \
    -e "s|DB_HOST=|DB_HOST=mariadb-database|" \
    -e "s/DB_PORT=/DB_PORT=3306/" \
    "$BENCH1_ENV"
  SITES1="\`$(IFS='\`,\`'; echo "${BENCH1_SITES[*]}")\`"
  {
    echo "SITES=${SITES1}"
    echo "ROUTER=${BENCH1_NAME}"
    echo "BENCH_NETWORK=${BENCH1_NAME}"
  } >> "$BENCH1_ENV"
fi

echo "Deploying first bench (${BENCH1_NAME})..."
docker compose \
  --project-name "${BENCH1_NAME}" \
  --env-file "$BENCH1_ENV" \
  -f "$FRAPPE_DOCKER_DIR/compose.yaml" \
  -f "$FRAPPE_DOCKER_DIR/overrides/compose.redis.yaml" \
  -f "$FRAPPE_DOCKER_DIR/overrides/compose.multi-bench.yaml" \
  -f "$FRAPPE_DOCKER_DIR/overrides/compose.multi-bench-ssl.yaml" \
  config > "$GITOPS_DIR/${BENCH1_NAME}.yaml"

docker compose --project-name "${BENCH1_NAME}" -f "$GITOPS_DIR/${BENCH1_NAME}.yaml" up -d

for site in "${BENCH1_SITES[@]}"; do
  echo "Creating site: ${site}"
  docker compose --project-name "${BENCH1_NAME}" exec backend \
    bench new-site --mariadb-user-host-login-scope=% \
    --db-root-password "${MARIADB_PASSWORD}" \
    --install-app erpnext --admin-password "${MARIADB_PASSWORD}" \
    "${site}"
done

echo "=== All done! Review logs with 'docker compose ps' and visit your sites. ==="