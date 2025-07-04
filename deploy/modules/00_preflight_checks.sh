#!/usr/bin/env bash

# Function to check if a command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

run_preflight_checks() {
  echo "### Running Pre-flight Checks..."
  if ! command_exists "git"; then
    echo "Error: git is not installed. Please install git and try again."
    exit 1
  fi
  if ! command_exists "curl"; then
    echo "Error: curl is not installed. Please install curl and try again."
    exit 1
  fi
  echo "### Pre-flight Checks Passed."
}