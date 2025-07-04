#!/usr/bin/env bash

deploy_database() {
  echo "### Deploying MariaDB..."

  local MARIADB_ENV="$GITOPS_DIR/mariadb.env"
  if [ ! -f "$MARIADB_ENV" ]; then
    echo "Configuring MariaDB environment..."
    echo "DB_PASSWORD=${MARIADB_PASSWORD}" > "$MARIADB_ENV"
  fi

  docker compose \
    --project-name mariadb \
    --env-file "$MARIADB_ENV" \
    -f "$FRAPPE_DOCKER_DIR/overrides/compose.mariadb-shared.yaml" \
    up -d
  echo "### MariaDB Deployed."
}