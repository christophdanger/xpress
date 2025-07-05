#!/usr/bin/env bash
#
# xpress: Main installer script
# Orchestrates the deployment of Frappe environments.

set -euo pipefail

# --- Source Configuration & Modules ---
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

source "${SCRIPT_DIR}/config.sh"
source "${SCRIPT_DIR}/modules/00_preflight_checks.sh"
source "${SCRIPT_DIR}/modules/01_install_dependencies.sh"
source "${SCRIPT_DIR}/modules/10_deploy_traefik.sh"
source "${SCRIPT_DIR}/modules/11_deploy_database.sh"
source "${SCRIPT_DIR}/modules/20_deploy_frappe.sh"
source "${SCRIPT_DIR}/modules/30_install_custom_app.sh"

# --- Main Execution ---

main() {
  # For now, we only have one deployment type.
  # This will be expanded later.
  local DEPLOYMENT_TYPE="single_server"

  case "$DEPLOYMENT_TYPE" in
    "single_server")
      echo "🚀 Starting Single Server Deployment..."
      run_preflight_checks
      install_dependencies
      deploy_traefik
      deploy_database
      deploy_frappe_bench
      install_custom_app "mmp_core" "https://github.com/christophdanger/mmp_core" "${BENCH1_SITES[0]}"
      ;;
    *)
      echo "Error: Unknown deployment type."
      exit 1
      ;;
  esac

  echo "✅ All done! Review logs with 'docker compose ps' and visit your sites."
}

# Run the main function
main "$@"