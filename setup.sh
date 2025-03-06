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
# In setup.sh, create these scripts instead of complex aliases:
mkdir -p ~/.local/bin

# Create init-cicd script
cat > ~/.local/bin/gh-init-cicd << 'EOF'
#!/bin/bash
if [ -z "$1" ]; then
  echo "Error: Template name required"
  echo "Usage: gh-init-cicd <category/template>"
  echo "Example: gh-init-cicd deploy/node"
  exit 1
fi

# Fetch template
~/.local/bin/gh-fetch-cicd "$1"

# Run setup script if available
if [ -f ./CD-*.template-setup.sh ]; then
  chmod +x ./CD-*.template-setup.sh 
  ./CD-*.template-setup.sh
fi
EOF

# Create fetch-cicd script
cat > ~/.local/bin/gh-fetch-cicd << 'EOF'
#!/bin/bash
if [ -z "$1" ]; then
  echo "Error: No template specified"
  echo "Usage: gh-fetch-cicd <category/template>"
  echo "Example: gh-fetch-cicd deploy/node"
  exit 1
fi

echo "Fetching template: $1"
echo "$1" > .template-source

# Template repo info
USERNAME="${GITHUB_USERNAME:-AlekOmOm}"
REPO="${REPO_NAME:-cicd-templates}"

# Fetch and copy template
TMP_DIR=$(mktemp -d)
gh repo clone $USERNAME/$REPO "$TMP_DIR" > /dev/null 2>&1

# Check if template exists
if [ ! -d "$TMP_DIR/templates/$1" ]; then
  echo "Error: Template $1 not found"
  rm -rf "$TMP_DIR"
  exit 1
fi

# Copy template files
mkdir -p cd-template.docs
mv "$TMP_DIR/templates/$1/"*.md cd-template.docs/ 2>/dev/null
cp -r "$TMP_DIR/templates/$1/"* . 2>/dev/null
cp -r "$TMP_DIR/templates/$1/".[!.]* . 2>/dev/null

rm -rf "$TMP_DIR"
echo "✓ Template $1 copied successfully\n"
EOF

# Create list-cicd script
cat > ~/.local/bin/gh-list-cicd << 'EOF'
#!/bin/bash
# Template repo info
USERNAME="${GITHUB_USERNAME:-AlekOmOm}"
REPO="${REPO_NAME:-cicd-templates}"

TMP_DIR=$(mktemp -d)
gh repo clone $USERNAME/$REPO "$TMP_DIR" > /dev/null 2>&1

echo -e "\nAvailable Templates:"
echo -e "-------------------"

for category in $(find "$TMP_DIR/templates" -mindepth 1 -maxdepth 1 -type d -exec basename {} \;); do
  echo -e "\n-- $category:"
  for template in $(ls -d "$TMP_DIR/templates/$category"/* 2>/dev/null | grep -v "\.git" | xargs -n1 basename 2>/dev/null); do
    echo "  ✓ $template  --  gh-fetch-cicd $category/$template"
  done
done

rm -rf "$TMP_DIR"
EOF


# Make scripts executable
chmod +x ~/.local/bin/gh-init-cicd
chmod +x ~/.local/bin/gh-fetch-cicd
chmod +x ~/.local/bin/gh-list-cicd

# remove existing aliases
gh alias delete init-cicd > /dev/null 2>&1
gh alias delete fetch-cicd > /dev/null 2>&1
gh alias delete list-cicd > /dev/null 2>&1

# Add simple aliases that just call the scripts

gh alias set init-cicd '!~/.local/bin/gh-init-cicd "$@"' --clobber > /dev/null 2>&1
gh alias set fetch-cicd '!~/.local/bin/gh-fetch-cicd "$@"' --clobber > /dev/null 2>&1
gh alias set list-cicd '!~/.local/bin/gh-list-cicd' --clobber > /dev/null 2>&1

# Add to PATH if needed

  #if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
  # export PATH="$HOME/.local/bin:$PATH"
    

  #  echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
  #  echo "Added ~/.local/bin to PATH in ~/.bashrc"
  #  echo "You may need to restart your shell or run 'source ~/.bashrc'"
  # fi

}

# Display usage examples
show_examples() {
  echo -e "\n${BLUE}Setup complete!${NC}"
  
  echo -e "\n${YELLOW}gh commands:${NC}"
  echo -e "  gh list-cicd"
  echo -e "  gh init-cicd <category>/<template>"
  echo -e "  gh fetch-cicd <category>/<template> \n"
  

  echo -e "\n${YELLOW}List available templates:${NC}"
  echo -e "  gh list-cicd"
  
  echo -e "\n${YELLOW}Fetch a CICD template into your project:${NC}"
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
  echo -e " "
  echo -e " "
  echo -e "${YELLOW}===== GitHub CI/CD Templates Setup =====${NC}"
  
  check_gh_cli
  check_gh_auth
  get_repo_info
  setup_aliases
  show_examples
  
  echo -e "\n${GREEN}✓ Setup completed successfully!${NC}"
  echo -e " "
}

# Run main function
main
