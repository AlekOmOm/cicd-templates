#!/bin/bash
# CD-node.template-setup.sh
# Setup script for Node.js CD template integration

# Colors for output
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}===== Node.js CD Template Setup =====${NC}"

# Get current directory
CURRENT_DIR=$(pwd)

### ------------------- Setup Steps ------------------- ###

# 0. Check Node.js installation
# 1. populate .env.config
# 2. Check/create package.json
# 3. Check server file structure
# 4. Check GitHub repo and secrets if possible
# 5. Make scripts executable
# 6. Remind about next steps
# 7. create .gitignore with npx gitignore node

### ---------

# 0. Check Node.js installation
echo -e "\n${YELLOW}0. Checking Node.js environment...${NC}"
if ! command -v node &> /dev/null; then
    echo -e "${RED}Node.js is not installed.${NC}"
    echo -e "Please install Node.js from: https://nodejs.org/"
    exit 1
fi

# Check node version
NODE_VERSION=$(node -v | cut -d 'v' -f 2)
echo -e "${GREEN}✓ Node.js ${NODE_VERSION} is installed${NC}"

# 1. populate .env.config
echo -e "\n${YELLOW}1. Checking your .env.config...${NC}"

if [ ! -f "scripts/populate_.env.config.sh" ]; then
    echo -e "${RED}Error: scripts/populate_.env.config.sh not found!${NC}"
    exit 1
else
    echo -e "${YELLOW}Populating .env.config...${NC}"
    bash scripts/populate_.env.config.sh
fi



# 2. Check/create package.json
echo -e "\n${YELLOW}2. Checking package.json...${NC}"
if [ ! -f "package.json" ]; then
    echo -e "${YELLOW}No package.json found. Creating one...${NC}"
    npm init -y
fi

# 3. Check server file structure
echo -e "\n${YELLOW}3. Checking server file structure...${NC}"
# Load NODE_SERVER_PATH from .env.config if exists
if [ -f "config/.env.config" ]; then
    SERVER_PATH=$(grep -oP 'NODE_SERVER_PATH=\K.*' config/.env.config | tr -d "'" | tr -d '"')
    if [ -z "$SERVER_PATH" ]; then
        SERVER_PATH="./src/server.js"
    fi
else
    echo -e "${RED}Error: config/.env.config not found!${NC}"
    echo -e "Please ensure you have fetched the template correctly using:"
    echo -e "  gh fetch-cicd deploy/node"
    exit 1
fi

echo -e "${YELLOW}Server path from config: ${SERVER_PATH}${NC}"

# Create directory if needed
SERVER_DIR=$(dirname "$SERVER_PATH")
if [ ! -d "$SERVER_DIR" ]; then
    echo -e "${YELLOW}Creating directory: $SERVER_DIR${NC}"
    mkdir -p "$SERVER_DIR"
fi

# Check if server file exists, create template if not
if [ ! -f "$SERVER_PATH" ]; then
    echo -e "${YELLOW}Creating a basic server.js template...${NC}"
    
    # Install express if needed
    if ! grep -q '"express"' package.json; then
        echo -e "${YELLOW}Installing express...${NC}"
        npm install express
    fi
    
    # Create server file template
    cat > "$SERVER_PATH" << 'EOF'
const express = require('express');

const app = express();
const port = process.env.PORT || 3000;

app.get('/', (req, res) => {
  res.send('Application is running!');
});

app.listen(port, () => {
  console.log(`Server listening on port ${port}`);
});
EOF
    echo -e "${GREEN}✓ Created $SERVER_PATH${NC}"
fi

# 4. Check GitHub repo and secrets if possible
echo -e "\n${YELLOW}Checking GitHub repository setup...${NC}"
if command -v gh &> /dev/null; then
    if gh repo view &> /dev/null; then
        echo -e "${GREEN}✓ GitHub repository exists${NC}"
        echo -e "${YELLOW}Reminder: You need to set up these GitHub secrets:${NC}"
        echo -e "  - SERVER_HOST: Your deployment server hostname/IP"
        echo -e "  - SERVER_USER: SSH username for deployment"
        echo -e "  - SSH_PRIVATE_KEY: Your SSH private key"
        echo -e "  - SSH_PORT: SSH port (usually 22)"
    else
        echo -e "${YELLOW}This directory is not a GitHub repository or you're not authenticated.${NC}"
        echo -e "Run 'gh auth login' and initialize a GitHub repository if needed."
    fi
else
    echo -e "${YELLOW}GitHub CLI not found. Cannot verify repository setup.${NC}"
fi

# 5. Make scripts executable
echo -e "\n${YELLOW}Making deployment scripts executable...${NC}"
if [ -d "scripts" ]; then
    chmod +x scripts/*.sh
    echo -e "${GREEN}✓ Scripts are now executable${NC}"
else
    echo -e "${RED}Error: scripts directory not found!${NC}"
    echo -e "Please ensure you have fetched the template correctly."
    exit 1
fi

# create .gitignore with npx gitignore node

# check if .gitignore exists
if [ -f ".gitignore" ]; then
    echo -e "\n${YELLOW}Existing .gitignore found.${NC}"
    echo -e " ${NC}"

    # confirm with user, otherwise install official Node.js template
    read -p "Would to replace with the official Node.js template? (y/n): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Replacing .gitignore ...${NC}"
        curl -o .gitignore https://raw.githubusercontent.com/github/gitignore/master/Node.gitignore
    fi
fi

# 6. Remind about next steps
echo -e "\n${GREEN}✓ Template setup completed!${NC}"
echo -e "\n${YELLOW}Next steps:${NC}"
echo -e "1. Verify settings in config/.env.config match your project requirements"
echo -e "2. Commit and push changes to trigger the CI/CD pipeline"

echo -e "\n${GREEN}Your Node.js project is now configured for CD deployment!${NC}"
