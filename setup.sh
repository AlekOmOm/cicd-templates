#!/usr/bin/env bash
# Setup script for cicd-templates
# This script sets up GitHub CLI aliases for the cicd-templates repository

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Default repository settings
DEFAULT_USERNAME="AlekOmOm"  # Your GitHub username
DEFAULT_REPO="cicd-templates"

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

# Function to detect if a repo is accessible
check_repo_access() {
  local username=$1
  local repo=$2
  
  if gh repo view "${username}/${repo}" &> /dev/null; then
    return 0  # Success
  else
    return 1  # Failure
  fi
}

# Function to prompt for repository info
get_repo_info() {
  local username=$DEFAULT_USERNAME
  local repo=$DEFAULT_REPO
  
  # Try the default first
  if check_repo_access "$username" "$repo"; then
    echo -e "${GREEN}✓ Using repository: ${username}/${repo}${NC}"
    GITHUB_USERNAME=$username
    REPO_NAME=$repo
    return
  fi
  
  # Try the authenticated user's fork
  local current_user=$(gh api user | grep -o '"login": *"[^"]*"' | sed 's/"login": *"\([^"]*\)"/\1/')
  if [ -n "$current_user" ] && check_repo_access "$current_user" "$repo"; then
    echo -e "${GREEN}✓ Found your fork: ${current_user}/${repo}${NC}"
    GITHUB_USERNAME=$current_user
    REPO_NAME=$repo
    return
  fi
  
  # Prompt for manual entry
  echo -e "${YELLOW}Unable to automatically detect the repository.${NC}"
  
  read -p "Enter GitHub username for cicd-templates repo (default: $DEFAULT_USERNAME): " input_username
  GITHUB_USERNAME=${input_username:-$DEFAULT_USERNAME}
  
  read -p "Enter repository name (default: $DEFAULT_REPO): " input_repo
  REPO_NAME=${input_repo:-$DEFAULT_REPO}
  
  # Verify the repo is accessible
  if ! check_repo_access "$GITHUB_USERNAME" "$REPO_NAME"; then
    echo -e "${RED}Repository ${GITHUB_USERNAME}/${REPO_NAME} is not accessible.${NC}"
    echo -e "Please check if:"
    echo -e "1. The repository exists"
    echo -e "2. The repository is public"
    echo -e "3. You have the correct permissions"
    
    read -p "Do you want to try again? (y/n): " retry
    if [[ $retry =~ ^[Yy]$ ]]; then
      get_repo_info
    else
      exit 1
    fi
  else
    echo -e "${GREEN}✓ Repository ${GITHUB_USERNAME}/${REPO_NAME} is accessible${NC}"
  fi
}

# Setup GitHub aliases
setup_aliases() {
  echo -e "\n${YELLOW}Setting up GitHub CLI aliases...${NC}"

  # init-cicd alias; combining fetch + init setup.sh
  # # runs 
  #  - fetch-cicd <template-name>
  #  - if CD-*.template-setup.sh exists, runs it
  # # Usage: gh init-cicd <template-name>
  INIT_ALIAS="!f() { echo \"Initializing template: \$1\"; gh fetch-cicd \"\$1\" && if [ -f ./CD-*.template-setup.sh ]; then chmod +x ./CD-*.template-setup.sh && ./CD-*.template-setup.sh; fi; }; f"
  
  # Define the fetch-cicd alias
  # # Fetches a template from the Repository
  #   - sets content at the root of the project
  # # Usage: gh fetch-cicd <template-name>
    FETCH_ALIAS="!f() { 
      if [ -z \"\$1\" ]; then
        echo \"Error: No template specified\";
        echo \"Usage: gh fetch-cicd category/template\";
        echo \"Example: gh fetch-cicd deploy/node\";
        exit 1;
      fi;
      echo \"Fetching template: \$1\"; 
      TMP_DIR=\$(mktemp -d); 
      gh repo clone $GITHUB_USERNAME/$REPO_NAME \"\$TMP_DIR\" > /dev/null 2>&1 && 
      mkdir -p cd-template.docs && 
      mv \"\$TMP_DIR/templates/\$1/\"*.md cd-template.docs/ 2>/dev/null;
      cp -r \"\$TMP_DIR/templates/\$1/\"* . 2>/dev/null && 
      cp -r \"\$TMP_DIR/templates/\$1/\".[!.]* . 2>/dev/null; 
      RET=\$?; 
      rm -rf \"\$TMP_DIR\"; 
      if [ \$RET -ne 0 ]; then 
        echo \"Template \$1 not found or error occurred\"; 
        exit 1; 
      else 
        echo \"✓ Template \$1 copied successfully\"; 
        echo \"Note: Template markdown files were saved to cd-template.docs/ to avoid overwriting project files\"; 
      fi;
    }; f" 

  # Define the list-cicd alias with improved formatting
  # # Lists available templates from the Repository
  #   - uses the templates directory structure
  # # Usage: gh list-cicd
  LIST_ALIAS="!f() { 
  echo \" \";
  echo \" templates:\"; 
  echo \"-------------------\"; 
  TMP_DIR=\$(mktemp -d); 
  gh repo clone $GITHUB_USERNAME/$REPO_NAME \"\$TMP_DIR\" > /dev/null 2>&1 && 
  echo \"\" &&
  for category in \$(find \"\$TMP_DIR/templates\" -mindepth 1 -maxdepth 1 -type d -exec basename {} \\;); do
    echo \"-- category: \$category\";
    echo \"----------\";
    for template in \$(ls -d \"\$TMP_DIR/templates/\$category\"/* 2>/dev/null | grep -v \"\\.git\" | xargs -n1 basename 2>/dev/null); do
      echo \"  ✓ \$template  --  gh fetch-cicd \$category/\$template\";
    done;
    echo \"\";
  done;
  rm -rf \"\$TMP_DIR\";
}; f"
  
  if gh alias list 2>/dev/null | grep -q "init-cicd"; then
    echo -e "${YELLOW}Updating existing init-cicd alias${NC}"
    gh alias delete init-cicd > /dev/null 2>&1
  fi

  if gh alias list 2>/dev/null | grep -q "fetch-cicd"; then
    echo -e "${YELLOW}Updating existing fetch-cicd alias${NC}"
    gh alias delete fetch-cicd > /dev/null 2>&1
  fi
  
  if gh alias list 2>/dev/null | grep -q "list-cicd"; then
    echo -e "${YELLOW}Updating existing list-cicd alias${NC}"
    gh alias delete list-cicd > /dev/null 2>&1
  fi
  
  # Set the aliases quietly (redirect output)
  gh alias set init-cicd "$INIT_ALIAS" > /dev/null
  gh alias set fetch-cicd "$FETCH_ALIAS" > /dev/null
  gh alias set list-cicd "$LIST_ALIAS" > /dev/null  

  # print available commands

  echo -e "${GREEN}✓ GitHub CLI aliases set up successfully${NC}"
  
  echo -e "\n${GREEN}Available commands:${NC}"
  echo -e "  ${YELLOW}gh list-cicd${NC} - List available templates"
  echo -e "  ${YELLOW}gh fetch-cicd <template-name>${NC} - Fetch a template into your project"
  echo -e "  ${YELLOW}gh init-cicd <template-name>${NC} - Fetch and initialize a template"
}

# Display usage examples
show_examples() {
  echo -e "\n${GREEN}Setup complete! You can now use the following commands:${NC}"
  echo -e "\n${YELLOW}List available templates:${NC}"
  echo -e "  gh list-cicd"
  
  echo -e "\n${YELLOW}Fetch a template into your project:${NC}"
  echo -e "  cd /path/to/your/project"
  echo -e "  gh fetch-cicd deploy/node"
  
  echo -e "\n${YELLOW}After fetching a template:${NC}"
  echo -e "  1. Customize .env.config with your project settings"
  echo -e "  2. Run 'npm install --save-dev dotenv' (if needed)"
  echo -e "  3. Apply configuration with 'node scripts/apply-config.js'"
  
  echo -e "\n${YELLOW}Repository used for templates:${NC}"
  echo -e "  https://github.com/${GITHUB_USERNAME}/${REPO_NAME}"
}

# Main function
main() {
  echo -e "${YELLOW}===== GitHub CI/CD Templates Setup =====${NC}"
  
  check_gh_cli
  check_gh_auth
  get_repo_info
  setup_aliases
  show_examples
  
  echo -e "\n${GREEN}✓ Setup completed successfully!${NC}"
}

# Run main function
main
