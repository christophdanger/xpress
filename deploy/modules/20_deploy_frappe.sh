#!/usr/bin/env bash

deploy_frappe_bench() {
  echo "### Deploying Frappe Bench (${BENCH1_NAME})..."

  local BENCH1_ENV="$GITOPS_DIR/${BENCH1_NAME}.env"
  if [ ! -f "$BENCH1_ENV" ]; then
    echo "Configuring bench environment (${BENCH1_NAME})..."
    cp "$FRAPPE_DOCKER_DIR/example.env" "$BENCH1_ENV"
    sed -i \
      -e "s/DB_PASSWORD=123/DB_PASSWORD=${MARIADB_PASSWORD}/" \
      -e "s|DB_HOST=|DB_HOST=mariadb-database|" \
      -e "s/DB_PORT=/DB_PORT=3306/" \
      "$BENCH1_ENV"
    local SITES1="\`$(IFS='\`,\`'; echo "${BENCH1_SITES[*]}")\`"
    {
      echo "SITES=${SITES1}"
      echo "ROUTER=${BENCH1_NAME}"
      echo "BENCH_NETWORK=${BENCH1_NAME}"
    } >> "$BENCH1_ENV"
  fi

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
  echo "### Frappe Bench Deployed."
}