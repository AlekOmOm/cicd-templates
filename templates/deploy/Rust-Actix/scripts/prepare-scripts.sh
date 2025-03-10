#!/bin/bash
# prepare-scripts.sh - Prepares all deployment scripts in one go

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "Preparing deployment scripts in $SCRIPT_DIR"

# Ensure directories exist
mkdir -p "$PROJECT_ROOT/config"

# Process all shell scripts
echo "Making scripts executable and ensuring Unix line endings"
find "$SCRIPT_DIR" -name "*.sh" -type f -exec chmod +x {} \; 
find "$SCRIPT_DIR" -name "*.sh" -type f -exec dos2unix {} \; 2>/dev/null || echo "Warning: dos2unix not available, skipping line ending conversion"

# Ensure env files have proper format
if [ -f "$PROJECT_ROOT/config/.env.deploy" ]; then
    dos2unix "$PROJECT_ROOT/config/.env.deploy" 2>/dev/null || echo "Warning: dos2unix not available, skipping line ending conversion"
fi

echo "Script preparation complete"
