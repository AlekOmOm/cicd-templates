#!/usr/bin/env bash
# Setup script for cicd-templates
# This script sets up GitHub CLI aliases for the cicd-templates repository

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# GitHub username and repository 
GITHUB_USERNAME="YOUR-USERNAME"  # Change this to your GitHub username
REPO_NAME="cicd-templates"

# Function to check if gh CLI is installed
check_gh_cli() {
  if ! command -v gh &> /dev/null; then
    echo -e "${RED}GitHub CLI (gh) is not installed.${NC}"
    echo -e "Please install it from: https://cli.github.com/"
    echo
    echo -e "Installation instructions:"
    echo -e "  - macOS: brew install gh"
    echo -e "  - Windows: winget install --id GitHub.cli"
    echo -e "  - Linux: follow https://github.com/cli/cli/blob/trunk/docs/install_linux.md"
    exit 1
  else
    echo -e "${GREEN}✓ GitHub CLI is installed${NC}"
  fi
}

# Check if user is authenticated with GitHub
check_gh_auth() {
  if ! gh auth status &> /dev/null; then
    echo -e "${YELLOW}You need to authenticate with GitHub CLI${NC}"
    echo -e "Running: gh auth login"
    gh auth login
  else
    echo -e "${GREEN}✓ GitHub CLI is authenticated${NC}"
  fi
}

# Setup GitHub aliases
setup_aliases() {
  echo -e "\n${YELLOW}Setting up GitHub CLI aliases...${NC}"
  
  # Define the fetch-cicd alias
  FETCH_ALIAS="!f() { echo \"Fetching template: \$1\"; TMP_DIR=\$(mktemp -d); gh repo clone $GITHUB_USERNAME/$REPO_NAME \"\$TMP_DIR\" > /dev/null 2>&1 && cp -r \"\$TMP_DIR/templates/\$1/\"* . 2>/dev/null; RET=\$?; rm -rf \"\$TMP_DIR\"; if [ \$RET -ne 0 ]; then echo \"Template \$1 not found or error occurred\"; exit 1; else echo \"Template \$1 copied successfully\"; fi; }; f"
  
  # Define the list-cicd alias
  LIST_ALIAS="!f() { echo \"Available templates:\"; TMP_DIR=\$(mktemp -d); gh repo clone $GITHUB_USERNAME/$REPO_NAME \"\$TMP_DIR\" > /dev/null 2>&1 && find \"\$TMP_DIR/templates\" -mindepth 1 -maxdepth 1 -type d -exec basename {} \\; | while read dir; do ls -d \"\$TMP_DIR/templates/\$dir\"/* >/dev/null 2>&1 && find \"\$TMP_DIR/templates/\$dir\" -mindepth 1 -maxdepth 1 -type d -exec basename {} \\; | sed \"s/^/\$dir\//\"; done; rm -rf \"\$TMP_DIR\"; }; f"
  
  # Check if aliases already exist
  if gh alias list | grep -q "fetch-cicd"; then
    echo -e "${YELLOW}Updating existing fetch-cicd alias${NC}"
    gh alias delete fetch-cicd > /dev/null
  fi
  
  if gh alias list | grep -q "list-cicd"; then
    echo -e "${YELLOW}Updating existing list-cicd alias${NC}"
    gh alias delete list-cicd > /dev/null
  fi
  
  # Set the aliases
  gh alias set fetch-cicd "$FETCH_ALIAS"
  gh alias set list-cicd "$LIST_ALIAS"
  
  echo -e "${GREEN}✓ GitHub CLI aliases set up successfully${NC}"
}

# Display usage examples
show_examples() {
  echo -e "\n${GREEN}Setup complete! You can now use the following commands:${NC}"
  echo -e "${YELLOW}gh list-cicd${NC} - List all available templates"
  echo -e "${YELLOW}gh fetch-cicd deploy/node${NC} - Fetch the node deployment template"
  echo
  echo -e "The templates will be copied to your current directory."
  echo -e "Remember to run fetch-cicd from the root of your project."
}

# Main function
main() {
  echo -e "${YELLOW}===== GitHub CI/CD Templates Setup =====${NC}"
  
  check_gh_cli
  check_gh_auth
  setup_aliases
  show_examples
  
  echo -e "\n${GREEN}Setup completed successfully!${NC}"
}

# Run main function
main
