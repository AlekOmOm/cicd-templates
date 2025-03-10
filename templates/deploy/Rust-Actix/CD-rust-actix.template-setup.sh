#!/bin/bash
# CD-rust-actix.template-setup.sh
# Setup script for Rust Actix-Web CD template integration

# Colors for output
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}===== Rust Actix-Web CD Template Setup =====${NC}"

# Get current directory
CURRENT_DIR=$(pwd)

### ------------------- Setup Steps ------------------- ###

# 0. Check Rust installation
# 1. Populate .env.config
# 2. Check/create Cargo.toml
# 3. Check project structure
# 4. Check GitHub repo and secrets if possible
# 5. Make scripts executable
# 6. Remind about next steps
# 7. Create .gitignore with Rust template

### ---------

# 0. Check Rust installation
echo -e "\n${YELLOW}0. Checking Rust environment...${NC}"
if ! command -v rustc &> /dev/null || ! command -v cargo &> /dev/null; then
    echo -e "${RED}Rust and/or Cargo are not installed.${NC}"
    echo -e "Please install Rust using rustup: https://rustup.rs/"
    exit 1
fi

# Check rust version
RUST_VERSION=$(rustc --version | cut -d ' ' -f 2)
echo -e "${GREEN}✓ Rust ${RUST_VERSION} is installed${NC}"

# 1. Populate .env.config
echo -e "\n${YELLOW}1. Checking your .env.config...${NC}"

if [ ! -f "scripts/populate_.env.config.sh" ]; then
    echo -e "${RED}Error: scripts/populate_.env.config.sh not found!${NC}"
    exit 1
else
    echo -e "${YELLOW}Populating .env.config...${NC}"
    bash scripts/populate_.env.config.sh
fi

# 2. Check/create Cargo.toml
echo -e "\n${YELLOW}2. Checking Cargo.toml...${NC}"
if [ ! -f "Cargo.toml" ]; then
    echo -e "${YELLOW}No Cargo.toml found. Creating a new Rust project...${NC}"
    cargo init --name app
    
    # Add actix-web dependency
    echo -e "${YELLOW}Adding actix-web dependencies...${NC}"
    cargo add actix-web
    cargo add env_logger
    cargo add log
    cargo add dotenvy
    
    echo -e "${GREEN}✓ Created new Rust project with Actix-Web dependencies${NC}"
else
    echo -e "${GREEN}✓ Cargo.toml found${NC}"
    
    # Check for actix-web dependency
    if ! grep -q "actix-web" Cargo.toml; then
        echo -e "${YELLOW}Adding actix-web dependencies...${NC}"
        cargo add actix-web
    fi
    
    # Check for env logging
    if ! grep -q "env_logger" Cargo.toml; then
        echo -e "${YELLOW}Adding env_logger dependency...${NC}"
        cargo add env_logger
    fi
    
    # Check for dotenvy
    if ! grep -q "dotenvy" Cargo.toml; then
        echo -e "${YELLOW}Adding dotenvy dependency...${NC}"
        cargo add dotenvy
    fi
fi

# 3. Check project structure
echo -e "\n${YELLOW}3. Checking project structure...${NC}"

# Load RUST_MAIN_PATH from .env.config if exists
if [ -f "config/.env.config" ]; then
    MAIN_PATH=$(grep -oP 'RUST_MAIN_PATH=\K.*' config/.env.config | tr -d "'" | tr -d '"')
    if [ -z "$MAIN_PATH" ]; then
        MAIN_PATH="./src/main.rs"
    fi
else
    echo -e "${RED}Error: config/.env.config not found!${NC}"
    echo -e "Please ensure you have fetched the template correctly using:"
    echo -e "  gh fetch-cicd deploy/rust_actix-web"
    exit 1
fi

echo -e "${YELLOW}Main path from config: ${MAIN_PATH}${NC}"

# Create directory if needed
MAIN_DIR=$(dirname "$MAIN_PATH")
if [ ! -d "$MAIN_DIR" ]; then
    echo -e "${YELLOW}Creating directory: $MAIN_DIR${NC}"
    mkdir -p "$MAIN_DIR"
fi

# Check if main file exists, create template if not
if [ ! -f "$MAIN_PATH" ]; then
    echo -e "${YELLOW}Creating a basic main.rs template...${NC}"
    
    cat > "$MAIN_PATH" << 'EOF'
use actix_web::{web, App, HttpResponse, HttpServer, Responder};
use dotenvy::dotenv;
use log::{info, LevelFilter};
use std::env;

async fn index() -> impl Responder {
    HttpResponse::Ok().body("Application is running!")
}

async fn health() -> impl Responder {
    HttpResponse::Ok().body("OK")
}

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    // Load .env file if it exists
    dotenv().ok();
    
    // Initialize logger
    env_logger::builder()
        .filter_level(LevelFilter::Info)
        .init();
    
    // Get port from environment or use default
    let port = env::var("PORT")
        .unwrap_or_else(|_| "8080".to_string())
        .parse::<u16>()
        .unwrap_or(8080);
    
    let host = env::var("HOST").unwrap_or_else(|_| "0.0.0.0".to_string());
    let bind_address = format!("{}:{}", host, port);
    
    info!("Starting server at: {}", bind_address);
    
    HttpServer::new(|| {
        App::new()
            .route("/", web::get().to(index))
            .route("/health", web::get().to(health))
    })
    .bind(bind_address)?
    .run()
    .await
}
EOF
    echo -e "${GREEN}✓ Created $MAIN_PATH${NC}"
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

# Create .gitignore with Rust template
if [ -f ".gitignore" ]; then
    echo -e "\n${YELLOW}Existing .gitignore found.${NC}"
    echo -e " ${NC}"

    # Confirm with user, otherwise install official Rust template
    read -p "Would you like to replace with the official Rust template? (y/n): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Replacing .gitignore ...${NC}"
        curl -o .gitignore https://raw.githubusercontent.com/github/gitignore/master/Rust.gitignore
    fi
else
    echo -e "${YELLOW}Creating .gitignore with Rust template...${NC}"
    curl -o .gitignore https://raw.githubusercontent.com/github/gitignore/master/Rust.gitignore
fi

# 6. Remind about next steps
echo -e "\n${GREEN}✓ Template setup completed!${NC}"
echo -e "\n${YELLOW}Next steps:${NC}"
echo -e "1. Verify settings in config/.env.config match your project requirements"
echo -e "2. Commit and push changes to trigger the CI/CD pipeline"
echo -e "3. Ensure your Rust application builds with 'cargo build --release'"

echo -e "\n${GREEN}Your Rust Actix-Web project is now configured for CD deployment!${NC}"
