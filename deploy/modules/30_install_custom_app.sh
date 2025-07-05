#!/usr/bin/env bash
# filepath: deploy/modules/30_install_custom_app.sh

install_custom_app() {
  local APP_NAME="$1"
  local APP_REPO="$2"
  local TARGET_SITE="$3"

  echo "### Installing custom app (${APP_NAME}) from repository (${APP_REPO})..."

  # Fetch and install the app using bench
  docker compose --project-name "${BENCH1_NAME}" exec backend \
    bench get-app --branch main "${APP_NAME}" "${APP_REPO}"

  # Install the app on the target site
  docker compose --project-name "${BENCH1_NAME}" exec backend \
    bench --site "${TARGET_SITE}" install-app "${APP_NAME}"

  echo "### Custom app (${APP_NAME}) installed successfully on site (${TARGET_SITE})."
}