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

build_custom_app_image() {
  local APP_NAME="$1"
  local APP_REPO="$2"
  
  echo "### Building custom Docker image with ${APP_NAME}..."
  
  # Create a custom Dockerfile in gitops directory
  local DOCKERFILE_DIR="${GITOPS_DIR}/custom_images"
  mkdir -p "${DOCKERFILE_DIR}"
  
  cat > "${DOCKERFILE_DIR}/Dockerfile.${BENCH1_NAME}" <<EOF
FROM frappe/frappe-worker:${FRAPPE_VERSION}
RUN install_app erpnext https://github.com/frappe/erpnext ${FRAPPE_VERSION#v}
RUN install_app ${APP_NAME} ${APP_REPO}
EOF
  
  # Build the custom image
  docker build -t custom-frappe-${BENCH1_NAME}:latest -f "${DOCKERFILE_DIR}/Dockerfile.${BENCH1_NAME}" .
  
  # Create a custom docker-compose override file
  cat > "${GITOPS_DIR}/${BENCH1_NAME}-custom.yaml" <<EOF
version: '3'
services:
  backend:
    image: custom-frappe-${BENCH1_NAME}:latest
  frontend:
    image: custom-frappe-${BENCH1_NAME}:latest
EOF

  echo "### Custom image built. Use ${GITOPS_DIR}/${BENCH1_NAME}-custom.yaml for deployment."
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