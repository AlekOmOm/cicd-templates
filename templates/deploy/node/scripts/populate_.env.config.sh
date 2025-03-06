#!/bin/bash
# populate_.env.config.sh
# Script to interactively populate .env.config file with user input
# Location: ./scripts/populate_.env.config.sh

### -------------------- populate .env.config file -------------------- ###
# 0. check if .env.config file exists
#  - if exists, ask to overwrite
#  - if not, create .env.config file
#  -> if overwrite/create -> continue 
#
# 1. use default .env.config.default file to populate .env.config
#  - check if default .env.config file exists 
#  - load variables from default .env.config file
#  - rm default .env.config.default file
#
# 2. get user input for each variable
#  <loop-start>
#  - print list of .env.config.default variables
#  - ask user input: 
#       - format: <line-number> <variable-value>
#  - overwrite any existing variables
#  - print updated .env.config file
#  - ask user to confirm
#       - repeat if user wants to change any variable
#  <loop-end>
#  - save .env.config file 
# 3. exit
### -------------

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

ENV_CONFIG_DIR="config"
ENV_CONFIG_FILE="${ENV_CONFIG_DIR}/.env.config"

# Create config directory if it doesn't exist
mkdir -p "$ENV_CONFIG_DIR"

# Check if .env.config file exists
if [ -f "$ENV_CONFIG_FILE" ]; then
    echo -e "${YELLOW}Found existing .env.config file.${NC}"
    read -p "Do you want to update it? (y/n, default: y): " update_config
    update_config=${update_config:-y}
    
    if [[ ! $update_config =~ ^[Yy]$ ]]; then
        echo -e "${GREEN}Keeping existing .env.config file.${NC}"
        exit 0
    fi

    # Make a backup of the existing file
    cp "$ENV_CONFIG_FILE" "${ENV_CONFIG_FILE}.bak"
    echo -e "${GREEN}Created backup at ${ENV_CONFIG_FILE}.bak${NC}"
else
    
    # Default content - will be used if no existing file
    cat > "$ENV_CONFIG_FILE" << 'EOF'
# Application Configuration
APP_NAME=deploy_node-simple
APP_DESCRIPTION="Test app for simple NodeJS CD pipeline"
APP_LICENSE=MIT
APP_VERSION=1.0.0

# Node.js Configuration
NODE_VERSION=18
NODE_VERSION_TAG=slim
NODE_MIN_VERSION=18.0.0
NODE_SERVER_PATH='./src/server.js'

# Docker Configuration
DOCKER_REGISTRY=ghcr.io
RESTART_POLICY=unless-stopped

# Environment Configuration
DEV_ENV=development
PROD_ENV=production
DEV_LOG_LEVEL=debug
PROD_LOG_LEVEL=info

# Deployment Configuration
DEV_BRANCH=dev
PROD_BRANCH=main

# Env Prod
PROD_PORT=8080
PROD_HOST=0.0.0.0
PROD_NODE_ENV=production
PROD_LOG_LEVEL=info
PROD_LOG_PATH=./logs
PROD_LOG_FILE=app.log

# Env dev
DEV_PORT=3000
DEV_HOST=0.0.0.0
DEV_NODE_ENV=development
DEV_LOG_LEVEL=debug
DEV_LOG_PATH=./logs
DEV_LOG_FILE=app.log

# Auto-Port Escalation (Optional)
AUTO_PORT_ESCALATE=true  # Set to false to disable automatic port escalation
 ## prod port range
PROD_PORT_RANGE_START=  # default is PROD_PORT
PROD_PORT_RANGE_END=    # default is 99 + PROD_PORT  
 ## dev port range
DEV_PORT_RANGE_START=   # default is DEV_PORT 
DEV_PORT_RANGE_END=     # default is 99 + DEV_PORT
EOF
fi

# Function to display the current configuration with line numbers
display_config() {
    echo -e "\n${BLUE}${BOLD}=== Current .env.config Variables ===${NC}"
    
    if [ -f "$ENV_CONFIG_FILE" ]; then
        # Display variables with line numbers
        line_num=1
        while IFS= read -r line; do
            # Skip comments and empty lines when showing as options
            if [[ ! "$line" =~ ^[[:space:]]*# && ! -z "$line" ]]; then
                printf "${GREEN}%3d${NC} | %s\n" $line_num "$line"
            else
                printf "    | %s\n" "$line"
            fi
            ((line_num++))
        done < "$ENV_CONFIG_FILE"
    fi
}

# Display current configuration
display_config

# Interactive setup
echo -e "\n${BLUE}${BOLD}=== .env.config Interactive Setup ===${NC}"

echo -e "   ${NC}"
echo -e " - type: 'done'    -> save & finish ${NC}"
echo -e " - type: 'refresh' -> see the updated config ${NC}"
echo -e " - type: 'quit'    -> exit & without save ${NC}\n"
echo -e "   ${NC}"
echo -e " - enter -> continue with the current configuration.${NC}\n"
echo -e "   ${NC}"
echo -e " edit by entering: ${NC}"
echo -e "${YELLOW}    <line-number> <variable-value>${NC}\n\n"
while true; do
    read -p "> " line_input
    
    # Exit loop if empty input
    if [ -z "$line_input" ]; then
        break
    fi
    
    # Parse line number and value
    line_num=$(echo "$line_input" | awk '{print $1}')
    new_value=$(echo "$line_input" | cut -d' ' -f2-)
    
    # Validate line number is a number
    if ! [[ "$line_num" =~ ^[0-9]+$ ]]; then
        echo -e "${RED}Invalid input. Line number must be a number.${NC}"
        continue
    fi
    
    # Get the line from the file
    line_content=$(sed "${line_num}q;d" "$ENV_CONFIG_FILE")
    
    # Check if line exists and is not a comment
    if [ -z "$line_content" ]; then
        echo -e "${RED}Line $line_num does not exist.${NC}"
        continue
    fi
    
    if [[ "$line_content" =~ ^[[:space:]]*# ]]; then
        echo -e "${RED}Line $line_num is a comment or empty line.${NC}"
        continue
    fi
    
    # Extract key from the line
    key=$(echo "$line_content" | cut -d'=' -f1)
    
    # Update the value
    if [[ "$new_value" == *" "* ]]; then
        # Value has spaces, add quotes
        sed -i "${line_num}s|^${key}=.*|${key}=\"${new_value}\"|" "$ENV_CONFIG_FILE"
    else
        sed -i "${line_num}s|^${key}=.*|${key}=${new_value}|" "$ENV_CONFIG_FILE"
    fi
    
    # Show the updated file
    display_config
    
    echo
done

# Display the final configuration and ask for confirmation
echo -e "\n${BLUE}${BOLD}Final Configuration:${NC}"
echo -e "${YELLOW}-------------------------${NC}"
display_config
echo -e "${YELLOW}-------------------------${NC}"

echo -n "Is this configuration correct? (y/n, default: y): "
read final_confirm
final_confirm=${final_confirm:-y}


if [[ $final_confirm =~ ^[Yy]$ ]]; then
    # Remove backup file
    rm ${ENV_CONFIG_FILE}.bak
    echo -e "\n${GREEN}✓ .env.config has been updated successfully!${NC}"
    echo -e "${GREEN}Configuration saved successfully!${NC}"
else
    echo -e "${YELLOW}Changes were not saved. Please run the script again to make additional changes.${NC}"
    cp "${ENV_CONFIG_FILE}.bak" "$ENV_CONFIG_FILE"
    echo -e "${GREEN}Restored the original config.${NC}"
    exit 1
fi

# Exit with success
exit 0