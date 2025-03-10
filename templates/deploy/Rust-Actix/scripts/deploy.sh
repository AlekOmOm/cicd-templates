#!/bin/bash
set -e

# Try to source deployment utilities if available
if [ -f "./scripts/deployment-utils.sh" ]; then
  source "./scripts/deployment-utils.sh"
else
  # Fallback logging function if utilities aren't available
  log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
  }
  log "Warning: deployment-utils.sh not found, using limited functionality"
fi

log "Starting deployment process"
log "Working directory: $(pwd)"

# Primary source of variables: .env.deploy
ENV_CONFIG_PATH="config/.env.deploy"

# Use load_environment from deployment-utils.sh if available, otherwise exit
if type load_environment &>/dev/null; then
  load_environment "$ENV_CONFIG_PATH" true
else
  log "Error: load_environment function not available and required"
  exit 1
fi

# Use check_required_vars from deployment-utils.sh if available, otherwise check manually
if type check_required_vars &>/dev/null; then
  check_required_vars DOCKER_REGISTRY IMAGE_NAME TAG CONTAINER_NAME PORT
else
  # Check for required variables
  for var in DOCKER_REGISTRY IMAGE_NAME TAG CONTAINER_NAME PORT; do
    if [ -z "${!var}" ]; then
      log "Error: Required variable $var is not set"
      exit 1
    fi
  done
fi

##################################################
# Deployment script logic

# Log configuration
log "Starting deployment of ${IMAGE_NAME}:${TAG}"
log "Environment: ${APP_ENV}"
log "Container: ${CONTAINER_NAME}"
log "Port: ${PORT}"


## ------------ Port Escalation Logic ------------ ##
# Check if auto port escalation is enabled and run if needed
#
if [ "${AUTO_PORT_ESCALATE:-false}" = "true" ]; then
  log "Auto port escalation is enabled"
  
  if [ -f "./scripts/auto_port-escalation.sh" ]; then
    log "Running auto port escalation script"
    chmod +x ./scripts/auto_port-escalation.sh
    ./scripts/auto_port-escalation.sh "$ENV_CONFIG_PATH"
    
    # If port was changed, reload environment variables
    if [ $? -eq 0 ]; then
      log "Port may have been changed, reloading environment"
      load_environment "$ENV_CONFIG_PATH" true
      log "Updated port: ${PORT}"
    fi
  else
    log "Warning: Auto port escalation is enabled but script not found at ./scripts/auto_port-escalation.sh"
  fi
fi


## ------------ Docker Availability Check ------------ ##

# Use check_docker_availability from deployment-utils.sh if available, otherwise check manually
if type check_docker_availability &>/dev/null; then
  check_docker_availability
else
  # Check if Docker is available
  if ! command -v docker &> /dev/null; then
    log "Error: Docker is not installed or not in PATH"
    exit 1
  fi

  if ! docker info &> /dev/null; then
    log "Error: Docker daemon is not running or current user doesn't have permissions"
    exit 1
  fi
fi

# Create image reference variables for clarity
SPECIFIC_IMAGE="${DOCKER_REGISTRY}/${IMAGE_NAME}:${TAG}"
LATEST_IMAGE="${DOCKER_REGISTRY}/${IMAGE_NAME}:${LATEST_TAG:-latest}"

# Pull latest image
log "Pulling latest image: $SPECIFIC_IMAGE"
if ! docker pull $SPECIFIC_IMAGE; then
  log "Failed to pull specific tag. Trying latest tag..."
  
  # Try to pull the latest tag for this environment
  if docker pull $LATEST_IMAGE; then
    # Update TAG to use the successfully pulled image
    export TAG="${LATEST_TAG:-latest}"
    log "Using image: $LATEST_IMAGE"
  else
    log "Error: Failed to pull both specific and latest image"
    exit 1
  fi
fi

# Ensure config files have proper format if utility exists
if type fix_env_format &>/dev/null; then
  log "Ensuring environment files are properly formatted"
  fix_env_format "$ENV_CONFIG_PATH" "$ENV_CONFIG_PATH"
fi

# First, check if our target container exists
if docker ps -a --format '{{.Names}}' | grep -Eq "^${CONTAINER_NAME}\$"; then
  log "Container ${CONTAINER_NAME} exists"
  
  # Check if it's using our target port
  if docker port ${CONTAINER_NAME} | grep -q ":${PORT}" || docker inspect --format='{{range $p, $conf := .HostConfig.PortBindings}}{{(index $conf 0).HostPort}}{{end}}' ${CONTAINER_NAME} | grep -q "${PORT}"; then
    log "Container ${CONTAINER_NAME} is using port ${PORT}. Stopping it..."
    docker stop ${CONTAINER_NAME} || log "Warning: Failed to stop container"
    
    log "Removing container ${CONTAINER_NAME}..."
    docker rm ${CONTAINER_NAME} || log "Warning: Failed to remove container"
  else
    log "Container ${CONTAINER_NAME} exists but is not using port ${PORT}. Stopping it anyway as we need the name..."
    docker stop ${CONTAINER_NAME} || log "Warning: Failed to stop container"
    
    log "Removing container ${CONTAINER_NAME}..."
    docker rm ${CONTAINER_NAME} || log "Warning: Failed to remove container"
  fi
  
  # Clean up related images
  if type cleanup_old_resources &>/dev/null; then
    log "Using utility to clean up old resources"
    cleanup_old_resources "${APP_ENV}"
  else
    log "Cleaning up old images for environment: ${APP_ENV}"
    docker image prune -f --filter "label=deployment.environment=${APP_ENV}" || true
  fi
else
  log "No container named ${CONTAINER_NAME} found"
fi

# Now check port availability to ensure port is free
if type check_port_availability &>/dev/null; then
  log "Checking if port ${PORT} is available on ${HOST:-0.0.0.0}"
  if ! check_port_availability "${PORT}" "${HOST:-0.0.0.0}"; then
    log "Error: Port ${PORT} is in use on ${HOST:-0.0.0.0} by a different service"
    log "Please either free up this port or configure a different port in the environment files"
    log "You may need to manually check what's using this port with: lsof -i :${PORT} or netstat -tuln | grep ${PORT}"
    exit 1
  else
    log "Port ${PORT} is available"
  fi
else
  log "Port availability check skipped (utility function not available)"
fi

# Starting container with docker-compose
log "Starting container with docker-compose"
if ! docker-compose up -d; then
  log "Error: Failed to start container with docker-compose"
  log "Trying docker run as fallback..."
  
  # Run with docker (container was already removed above if it existed)
  docker run -d \
    --name ${CONTAINER_NAME} \
    --restart ${RESTART_POLICY:-unless-stopped} \
    -p ${PORT}:${PORT} \
    -e PORT=${PORT} \
    -e APP_ENV=${APP_ENV} \
    -e APP_NAME=${APP_NAME} \
    -e APP_VERSION=${APP_VERSION} \
    ${DOCKER_REGISTRY}/${IMAGE_NAME}:${TAG}
fi

# Record deployment start time for metrics
DEPLOY_START_TIME=$(date +%s)

# Use verify_deployment from deployment-utils.sh if available, otherwise verify manually
if type verify_deployment &>/dev/null; then
  log "Verifying deployment using utility function"
  if ! verify_deployment "localhost" "${PORT}" 3 5; then
    log "❌ Deployment verification failed. Check container logs with: docker logs ${CONTAINER_NAME}"
    # Optional: add rollback logic here if verification fails
    exit 1
  fi
else
  # Verify deployment manually
  log "Verifying deployment..."
  sleep 5
  STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:${PORT}/ || echo "failed")

  if [ "$STATUS" = "200" ]; then
    log "✅ Deployment successful! Application is running."
  else
    log "❌ Deployment verification failed. Status: ${STATUS}"
    log "Check container logs with: docker logs ${CONTAINER_NAME}"
    exit 1
  fi
fi

# Calculate deployment time for metrics
DEPLOY_END_TIME=$(date +%s)
DEPLOY_DURATION=$((DEPLOY_END_TIME - DEPLOY_START_TIME))
log "Total deployment time: ${DEPLOY_DURATION} seconds"

log "Deployment completed successfully"
