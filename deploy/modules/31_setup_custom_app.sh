#!/usr/bin/env bash

setup_custom_app() {
  local APP_NAME="$1"
  local APP_REPO="$2"
  local TARGET_SITE="$3"
  local DEPLOYMENT_MODE="${4:-runtime}"  # Default to runtime installation
  
  echo "### Setting up custom app (${APP_NAME}) using ${DEPLOYMENT_MODE} mode..."
  
  if [ "${DEPLOYMENT_MODE}" == "production" ]; then
    # Production mode: Build custom Docker image
    build_custom_app_image "${APP_NAME}" "${APP_REPO}"
    
    # Update the docker-compose configuration to use custom images
    docker compose \
      --project-name "${BENCH1_NAME}" \
      --env-file "$GITOPS_DIR/${BENCH1_NAME}.env" \
      -f "$FRAPPE_DOCKER_DIR/compose.yaml" \
      -f "$FRAPPE_DOCKER_DIR/overrides/compose.redis.yaml" \
      -f "$FRAPPE_DOCKER_DIR/overrides/compose.multi-bench.yaml" \
      -f "$FRAPPE_DOCKER_DIR/overrides/compose.multi-bench-ssl.yaml" \
      -f "$GITOPS_DIR/${BENCH1_NAME}-custom.yaml" \
      up -d
      
    # Install the app on the site
    docker compose --project-name "${BENCH1_NAME}" exec backend \
      bench --site "${TARGET_SITE}" install-app "${APP_NAME}"
      
  else
    # Runtime mode: Install app at runtime
    install_custom_app "${APP_NAME}" "${APP_REPO}" "${TARGET_SITE}"
  fi
}

build_custom_app_images() {
  local APP_NAME="$1"
  local APP_REPO="$2"
  
  echo "### Building custom Docker images with ${APP_NAME}..."
  
  # Create directory for Dockerfiles
  local DOCKERFILE_DIR="${GITOPS_DIR}/custom_images"
  mkdir -p "${DOCKERFILE_DIR}"
  
  # 1. Create worker Dockerfile (for backend processes)
  cat > "${DOCKERFILE_DIR}/Dockerfile.worker" <<EOF
# Base worker image - handles Python backend processes
FROM frappe/frappe-worker:${FRAPPE_BRANCH_VERSION}

# Install ERPNext first (dependency)
RUN install_app erpnext https://github.com/frappe/erpnext ${FRAPPE_BRANCH_VERSION#version-}

# Install your custom app
RUN install_app ${APP_NAME} ${APP_REPO}
EOF
  
  # 2. Create nginx Dockerfile (for frontend assets)
  cat > "${DOCKERFILE_DIR}/Dockerfile.nginx" <<EOF
# Base nginx image - handles web serving and assets
FROM frappe/frappe-nginx:${FRAPPE_BRANCH_VERSION}

# Install ERPNext first (for frontend assets)
RUN install_app erpnext https://github.com/frappe/erpnext ${FRAPPE_BRANCH_VERSION#version-}

# Install your custom app's frontend assets
RUN install_app ${APP_NAME} ${APP_REPO}
EOF
  
  # Build the worker image (using frappe_docker as context)
  echo "Building custom worker image..."
  docker build -t custom-frappe-worker-${BENCH1_NAME}:latest \
    -f "${DOCKERFILE_DIR}/Dockerfile.worker" "${FRAPPE_DOCKER_DIR}"
  
  # Build the nginx image (using frappe_docker as context)
  echo "Building custom nginx image..."
  docker build -t custom-frappe-nginx-${BENCH1_NAME}:latest \
    -f "${DOCKERFILE_DIR}/Dockerfile.nginx" "${FRAPPE_DOCKER_DIR}"
  
  # Create docker-compose override to use these images
  cat > "${GITOPS_DIR}/${BENCH1_NAME}-custom.yaml" <<EOF
version: '3'
services:
  backend:
    image: custom-frappe-worker-${BENCH1_NAME}:latest
  frontend:
    image: custom-frappe-nginx-${BENCH1_NAME}:latest
EOF

  echo "### Custom images built for both backend and frontend services."
}

install_custom_app() {
  local APP_NAME="$1"
  local APP_REPO="$2"
  local TARGET_SITE="$3"

  echo "### Installing custom app (${APP_NAME}) from repository (${APP_REPO})..."

  # Check if app is already installed
  if docker compose --project-name "${BENCH1_NAME}" exec backend bash -c "[ -d /home/frappe/frappe-bench/apps/${APP_NAME} ]"; then
    echo "App ${APP_NAME} is already installed. Skipping installation."
  else
    # Fetch and install the app using bench
    docker compose --project-name "${BENCH1_NAME}" exec backend \
      bench get-app "${APP_NAME}" "${APP_REPO}"
  fi

  # Install the app on the site (if not already installed)
  if ! docker compose --project-name "${BENCH1_NAME}" exec backend \
      bench --site "${TARGET_SITE}" list-apps | grep -q "${APP_NAME}"; then
    docker compose --project-name "${BENCH1_NAME}" exec backend \
      bench --site "${TARGET_SITE}" install-app "${APP_NAME}"
  fi

  # Restart services to ensure the app is properly loaded
  docker compose --project-name "${BENCH1_NAME}" restart backend websocket scheduler worker-short worker-long

  echo "### Custom app (${APP_NAME}) installed successfully on site (${TARGET_SITE})."
}