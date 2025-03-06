#!/bin/bash

# Common logging function
log() {
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

# Load environment variables from file, using line-by-line parsing
load_environment() {
  local env_file=$1
  local required=${2:-true}  # By default, file is required
  
  # Check if file exists
  if [ ! -f "$env_file" ]; then
    log "Warning: Environment file not found at $env_file"
    exit 1
  fi
    
  log "Loading deployment variables from $env_file"
  
  # Process each line
  while IFS='=' read -r key value || [ -n "$key" ]; do
    # Skip empty lines and comments
    if [[ -z "$key" || "$key" =~ ^[[:space:]]*# ]]; then
      continue
    fi
    
    # Check if key looks like a valid variable name after trimming
    key_trimmed=$(echo "$key" | xargs)
    if [[ "$key_trimmed" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]]; then
      # Trim whitespace from value
      value_trimmed=$(echo "$value" | xargs)
      
      # Export the variable
      export "$key_trimmed=$value_trimmed"
    else
      log "Warning: Skipping invalid variable name in $env_file: $key"
    fi
  done < "$env_file"
  
  return 0
}

# Check for required environment variables
check_required_vars() {
  local required_vars=("$@")
  local missing_vars=0
  
  for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; then
      log "Error: Required variable $var is not set"
      missing_vars=$((missing_vars+1))
    fi
  done
  
  if [ $missing_vars -gt 0 ]; then
    log "Error: $missing_vars required variables are missing"
    return 1
  fi
  
  return 0
}

# Verify deployment is running
verify_deployment() {
  local host=${1:-"localhost"}
  local port=${2:-$PORT}
  local retries=${3:-3}
  local wait_time=${4:-5}
  
  log "Verifying deployment on http://$host:$port/"
  
  for i in $(seq 1 $retries); do
    log "Attempt $i of $retries..."
    sleep $wait_time
    
    STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://$host:$port/ || echo "failed")

    if [ "$STATUS" = "200" ]; then
      log "✅ Deployment successful! Application is running."
      return 0
    else
      log "⚠️ Attempt $i: Status code $STATUS"
    fi
  done
  
  log "❌ Deployment verification failed after $retries attempts."
  log "Check container logs with: docker logs ${CONTAINER_NAME:-app}"
  return 1
}

# Clean up old resources
cleanup_old_resources() {
  local env=${1:-$APP_ENV}
  
  if [ -n "$env" ]; then
    log "Cleaning up old images for environment: $env"
    docker image prune -f --filter "label=deployment.environment=$env"
  else
    log "Warning: No environment specified for cleanup, skipping"
  fi
}

# Check Docker availability
check_docker_availability() {
  if ! command -v docker &> /dev/null; then
    log "Error: Docker is not installed or not in PATH"
    return 1
  fi
  
  if ! docker info &> /dev/null; then
    log "Error: Docker daemon is not running or current user doesn't have permissions"
    return 1
  fi
  
  if ! command -v docker-compose &> /dev/null; then
    if docker compose version &> /dev/null; then
      log "Using Docker Compose plugin format"
      # Create an alias for compatibility
      alias docker-compose="docker compose"
    else
      log "Error: Docker Compose is not installed"
      return 1
    fi
  fi
  
  return 0
}

# Fix set-env.sh output to ensure proper format
fix_env_format() {
  local input_file=$1
  local output_file=${2:-$input_file}
  
  if [ ! -f "$input_file" ]; then
    log "Error: Cannot fix format of non-existent file: $input_file"
    return 1
  fi
  
  # Create a temporary file
  local temp_file=$(mktemp)
  
  # Process file line by line, preserving more of the original format
  while IFS= read -r line || [ -n "$line" ]; do
    # Skip empty lines and comments
    if [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]]; then
      echo "$line" >> "$temp_file"
      continue
    fi
    
    # Check for lines with no equals sign
    if [[ "$line" != *"="* ]]; then
      log "Warning: Skipping line without assignment: $line"
      # Comment out the problematic line
      echo "# INVALID FORMAT: $line" >> "$temp_file"
      continue
    fi
    
    # Split on the first equals sign only
    key_part="${line%%=*}"
    value_part="${line#*=}"
    
    # Trim whitespace
    key_trimmed=$(echo "$key_part" | xargs)
    
    # Check if key is a valid variable name
    if [[ "$key_trimmed" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]]; then
      # Keep the variable - original approach just trims whitespace
      echo "$key_trimmed=$value_part" >> "$temp_file"
    else
      log "Warning: Invalid variable name: $key_trimmed"
      # Comment out the problematic line
      echo "# INVALID FORMAT: $line" >> "$temp_file"
    fi
  done < "$input_file"
  
  # Replace original file if output is the same
  if [ "$input_file" = "$output_file" ]; then
    mv "$temp_file" "$input_file"
  else
    mv "$temp_file" "$output_file"
  fi
  
  log "Fixed environment file format: $output_file"
  return 0
}

# Check if port is available
check_port_availability() {
  local port=$1
  local host=${2:-"0.0.0.0"}
  
  if command -v netstat &> /dev/null; then
    if netstat -tuln | grep -q "${host}:${port}"; then
      return 1
    fi
  elif command -v ss &> /dev/null; then
    if ss -tuln | grep -q "${host}:${port}"; then
      return 1
    fi
  else
    log "Warning: Neither netstat nor ss available to check port availability"
  fi
  
  return 0
}
