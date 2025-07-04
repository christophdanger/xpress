#!/usr/bin/env bash

# --- Core Directories ---
export WORKDIR="/opt/frappe"
export GITOPS_DIR="${WORKDIR}/gitops"
export FRAPPE_DOCKER_DIR="${WORKDIR}/frappe_docker"
export FRAPPE_DOCKER_REPO="https://github.com/christophdanger/devburner-frappe_docker.git"

# --- Traefik Configuration ---
export TRAEFIK_DOMAIN="traefik.example.com"
export TRAEFIK_EMAIL="user@example.com"
export TRAEFIK_PASSWORD="##################"

# --- MariaDB Configuration ---
export MARIADB_PASSWORD="##################"

# --- Bench & Site Configuration ---
export BENCH1_NAME="erpnext-one"
export BENCH1_SITES=("erp.example.com") # List of sites for bench1