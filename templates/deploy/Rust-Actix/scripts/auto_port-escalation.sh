#!/bin/bash
# Script for auto port escalation
# Only runs when AUTO_PORT_ESCALATE=true in .env.config

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Source utilities for logging if available
if [ -f "$SCRIPT_DIR/deployment-utils.sh" ]; then
  source "$SCRIPT_DIR/deployment-utils.sh"
else
  # Fallback logging
  log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
  }
fi

# Config file path (passed as argument or use default)
ENV_CONFIG_PATH="${1:-$PROJECT_ROOT/config/.env.deploy}"

log "Auto port escalation: Checking configuration"

# Load environment variables from the env file
if [ -f "$ENV_CONFIG_PATH" ]; then
  # Extract AUTO_PORT_ESCALATE setting
  AUTO_PORT_ESCALATE=$(grep -oP '^AUTO_PORT_ESCALATE=\K.*' "$ENV_CONFIG_PATH" | tr -d '"' | tr -d "'")
  
  # Extract PORT value
  PORT=$(grep -oP '^PORT=\K\d+' "$ENV_CONFIG_PATH" || echo "")
  
  # Extract HOST value
  HOST=$(grep -oP '^HOST=\K[0-9.]+' "$ENV_CONFIG_PATH" || echo "0.0.0.0")
  
  # Extract port range 
  PORT_RANGE_START=$(grep -oP '^PORT_RANGE_START=\K\d+' "$ENV_CONFIG_PATH" || echo "$((PORT + 100))")
  PORT_RANGE_END=$(grep -oP '^PORT_RANGE_END=\K\d+' "$ENV_CONFIG_PATH" || echo "$((PORT + 200))")
else
  log "Environment file not found at $ENV_CONFIG_PATH"
  exit 1
fi

# Skip if not enabled or port not found
if [ "${AUTO_PORT_ESCALATE:-false}" != "true" ]; then
  log "Auto port escalation is disabled (AUTO_PORT_ESCALATE != true)"
  exit 0
fi

if [ -z "$PORT" ]; then
  log "Could not determine PORT from $ENV_CONFIG_PATH"
  exit 1
fi

log "Auto port escalation: Checking if port $PORT is available on $HOST"
log "Using port range $PORT_RANGE_START-$PORT_RANGE_END"

# Check if current port is available (reusing utility function if possible)
PORT_AVAILABLE=true
if type check_port_availability &>/dev/null; then
  if ! check_port_availability "$PORT" "$HOST"; then
    PORT_AVAILABLE=false
  fi
else
  # Fallback port check
  if command -v netstat &> /dev/null; then
    if netstat -tuln | grep -q "${HOST}:${PORT}"; then
      PORT_AVAILABLE=false
    fi
  elif command -v ss &> /dev/null; then
    if ss -tuln | grep -q "${HOST}:${PORT}"; then
      PORT_AVAILABLE=false
    fi
  else
    log "Warning: Neither netstat nor ss available to check port availability"
    exit 0
  fi
fi

# If current port is available, exit early
if [ "$PORT_AVAILABLE" = true ]; then
  log "Port $PORT is available, no escalation needed"
  exit 0
fi

# Find next available port
log "Port $PORT is in use, searching for available port in range $PORT_RANGE_START-$PORT_RANGE_END..."
NEW_PORT=$PORT_RANGE_START
PORT_FOUND=false

# Search through the configured range
while [ $NEW_PORT -le $PORT_RANGE_END ]; do
  # Check if new port is available
  if type check_port_availability &>/dev/null; then
    if check_port_availability "$NEW_PORT" "$HOST"; then
      PORT_FOUND=true
      break
    fi
  else
    # Fallback port check
    PORT_IN_USE=false
    if command -v netstat &> /dev/null; then
      if netstat -tuln | grep -q "${HOST}:${NEW_PORT}"; then
        PORT_IN_USE=true
      fi
    elif command -v ss &> /dev/null; then
      if ss -tuln | grep -q "${HOST}:${NEW_PORT}"; then
        PORT_IN_USE=true
      fi
    fi
    
    if [ "$PORT_IN_USE" = false ]; then
      PORT_FOUND=true
      break
    fi
  fi
  
  NEW_PORT=$((NEW_PORT + 1))
done

# Update config if available port found
if [ "$PORT_FOUND" = true ]; then
  log "Found available port: $NEW_PORT (original was $PORT)"
  
  # Update the config file
  sed -i "s/^PORT=$PORT/PORT=$NEW_PORT/" "$ENV_CONFIG_PATH"
  
  # Create a record of the port change
  echo "$(date +'%Y-%m-%d %H:%M:%S') | Port auto-escalated from $PORT to $NEW_PORT for deployment ID: $(grep -oP '^DEPLOYMENT_ID=\K.*' "$ENV_CONFIG_PATH" || echo "unknown")" >> "$PROJECT_ROOT/port_changes.log"
  
  # Return success
  exit 0
else
  log "Error: Could not find available port in range $PORT_RANGE_START-$PORT_RANGE_END"
  log "All ports in the configured range are in use"
  exit 1
fi
