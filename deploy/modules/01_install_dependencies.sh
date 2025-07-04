#!/usr/bin/env bash

install_dependencies() {
  echo "### Installing Dependencies..."

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
    git clone "$FRAPPE_DOCKER_REPO" "$FRAPPE_DOCKER_DIR"
  else
    echo "frappe_docker repository already exists. Skipping clone."
  fi

  # Install Docker if not already installed
  if ! command_exists docker; then
    echo "Installing Docker..."
    curl -fsSL https://get.docker.com | bash
    sudo usermod -aG docker "$USER"
    echo "Docker installed. You may need to log out and log back in for group changes to take effect."
  else
    echo "Docker is already installed. Skipping installation."
  fi

  # Install Docker Compose v2 plugin if not already installed
  DOCKER_COMPOSE_PATH="/usr/local/lib/docker/cli-plugins/docker-compose"
  if ! command_exists docker-compose && [ ! -f "$DOCKER_COMPOSE_PATH" ]; then
    echo "Installing Docker Compose v2 plugin..."
    sudo mkdir -p "$(dirname "$DOCKER_COMPOSE_PATH")"
    sudo curl -SL https://github.com/docker/compose/releases/download/v2.2.3/docker-compose-linux-x86_64 \
         -o "$DOCKER_COMPOSE_PATH"
    sudo chmod +x "$DOCKER_COMPOSE_PATH"
  else
    echo "Docker Compose is already installed. Skipping installation."
  fi
  echo "### Dependencies Installed."
}