#!/bin/bash
# Script for determining environment variables based on branch

# Source the configuration file first
if [ -f "./config/.env.config" ]; then
  set -a
  source "./config/.env.config"
  set +a
else
  echo "Warning: config/.env.config not found, using fallback values"
fi

# Accept environment variables from parameters if available
GIT_BRANCH=${1:-${GITHUB_REF_NAME:-""}}
GIT_COMMIT=${2:-${GITHUB_SHA:-""}}

# Try to get Git info if not provided and in a Git repository
if [ -z "$GIT_BRANCH" ] && command -v git &> /dev/null && git rev-parse --is-inside-work-tree &> /dev/null; then
  GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
  GIT_COMMIT=$(git rev-parse HEAD)
fi

# Set fallback values if Git info is still missing
if [ -z "$GIT_BRANCH" ]; then
  if [ -n "$APP_ENV" ] && [ "$APP_ENV" = "production" ]; then
    GIT_BRANCH="main"
  else
    GIT_BRANCH="dev"
  fi
  echo "# Warning: Using fallback branch $GIT_BRANCH" >&2
fi

if [ -z "$GIT_COMMIT" ]; then
  GIT_COMMIT=$(date +%Y%m%d%H%M%S)
  echo "# Warning: Using timestamp as commit ID" >&2
fi

# Convert to lowercase for Docker compatibility
APP_NAME=$(echo ${APP_NAME:-deploy_node-simple} | tr '[:upper:]' '[:lower:]')
GITHUB_USERNAME=$(echo ${GITHUB_USERNAME:-alekomom} | tr '[:upper:]' '[:lower:]')
# CONTAINER_NAME deliberately not set in config/.env.config, since it is important to generate for docker container handling 
CONTAINER_NAME=${APP_NAME}

# mkdir config if not exists
mkdir -p config

# Based on Branch set specific environment variables
if [[ $GIT_BRANCH == "main" || $GIT_BRANCH == "master" ]]; then
  # Production environment
  echo "APP_ENV=${PROD_ENV:-production}"
  echo "PORT=${PROD_PORT:-8080}"
  echo "HOST=${PROD_HOST:-0.0.0.0}"
  
  # Production-specific image name
  # # prod has no suffix 
  echo "IMAGE_NAME=$(echo ${GITHUB_USERNAME}/${APP_NAME} | tr '[:upper:]' '[:lower:]')"
  echo "CONTAINER_NAME=$(echo ${CONTAINER_NAME:-${APP_NAME}} | tr '[:upper:]' '[:lower:]')"
  
  # Two tags: short commit and latest-production
  echo "TAG=$(echo ${GIT_COMMIT} | cut -c1-11)"
  echo "LATEST_TAG=latest"
  
  echo "NODE_ENV=${PROD_NODE_ENV:-production}"
  echo "LOG_LEVEL=${PROD_LOG_LEVEL:-info}"
  echo "DEPLOYMENT_PATH=~/app-deployment/production"
  
  # Set port range for auto port escalation in production
  if [ "${AUTO_PORT_ESCALATE:-false}" = "true" ]; then
    echo "PORT_RANGE_START=${PROD_PORT_RANGE_START:-$((PROD_PORT))}"
    echo "PORT_RANGE_END=${PROD_PORT_RANGE_END:-$((PROD_PORT_RANGE_START:-$((PROD_PORT)) + 99))}"
  fi
  
else
  # Development environment
  echo "APP_ENV=${DEV_ENV:-development}"
  echo "PORT=${DEV_PORT:-3000}"
  echo "HOST=${DEV_HOST:-0.0.0.0}"
  
  # Development-specific image name
  echo "IMAGE_NAME=$(echo ${GITHUB_USERNAME}/${APP_NAME}-dev | tr '[:upper:]' '[:lower:]')"
  # setting -dev to container name in either case of CONTAINER_NAME or APP_NAME, since both need -dev suffix
  echo "CONTAINER_NAME=$(echo ${CONTAINER_NAME:-${APP_NAME}}-dev | tr '[:upper:]' '[:lower:]')"
  
  # Two tags: short commit and latest-development
  echo "TAG=$(echo ${GIT_COMMIT} | cut -c1-11)"
  echo "LATEST_TAG=latest"
  
  echo "NODE_ENV=${DEV_NODE_ENV:-development}"
  echo "LOG_LEVEL=${DEV_LOG_LEVEL:-debug}"
  echo "DEPLOYMENT_PATH=~/app-deployment/development"
  
  # Set port range for auto port escalation in development
  if [ "${AUTO_PORT_ESCALATE:-false}" = "true" ]; then
    echo "PORT_RANGE_START=${DEV_PORT_RANGE_START:-$((DEV_PORT))}"
    echo "PORT_RANGE_END=${DEV_PORT_RANGE_END:-$((DEV_PORT_RANGE_START:-$((DEV_PORT)) + 99))}"
  fi
fi

# Common variables for both environments
echo "GIT_BRANCH=${GIT_BRANCH}"
echo "GIT_COMMIT=${GIT_COMMIT}" 
echo "DEPLOYMENT_SHA=${GIT_COMMIT}"

# application Configuration
echo "APP_NAME=${APP_NAME}"
echo "APP_DESCRIPTION=${APP_DESCRIPTION:-Simple Node.js application}"
echo "APP_LICENSE=${APP_LICENSE:-MIT}"
echo "APP_VERSION=${APP_VERSION:-1.0.0}"

# Node.js Configuration
echo "NODE_VERSION=${NODE_VERSION:-lts}"
echo "NODE_VERSION_TAG=${NODE_VERSION_TAG:-slim}"
echo "NODE_MIN_VERSION=${NODE_MIN_VERSION:-18.0.0}"
echo "NODE_SERVER_PATH=${NODE_SERVER_PATH:-server.js}"

# Docker Configuration
echo "DOCKER_REGISTRY=${DOCKER_REGISTRY:-ghcr.io}"
echo "RESTART_POLICY=${RESTART_POLICY:-unless-stopped}"

# Port Auto-Escalation Configuration
if [ "${AUTO_PORT_ESCALATE:-false}" = "true" ]; then
  echo "AUTO_PORT_ESCALATE=true"
  # Default fallback values if not set in branch-specific sections
  if [ -z "${PORT_RANGE_START}" ]; then
    echo "PORT_RANGE_START=$((PORT + 100))"
  fi
  if [ -z "${PORT_RANGE_END}" ]; then
    echo "PORT_RANGE_END=$((PORT + 200))"
  fi
else
  echo "AUTO_PORT_ESCALATE=false"
fi

# Deployment Specifications 
echo "DEPLOYMENT_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ')"
echo "DEPLOYMENT_ID=${APP_NAME}-${GIT_BRANCH}-$(echo ${GIT_COMMIT} | cut -c1-7)"
