# Welcome Dev! 
[for Contributors](./CONTRIBUTING.md)

## use cases

as a *dev*, I can...
- ***init** my project with CD-pipeline for Node.JS express app*

pre-requisites:

- server ready

## 🚀 **GitHub CI/CD Templates Setup**  

### Quick Start

1. **Setup**: `curl -s https://raw.githubusercontent.com/AlekOmOm/cicd-templates/main/setup.sh | bash`
2. **View templates**: `gh list-cicd`
3. **Apply template**: `cd your-project && gh init-cicd deploy/node`
4. **Configure**: Edit `config/.env.config`
5. **Deploy**: Push to GitHub

---
### 📂 **Directory Structure**  
```
cicd-templates/
  ├── templates/
  │     ├── deploy/          # deployment setups (github actions, docker, env configs)
  │     ├── integrate/       # ci workflows (testing, linting, security scans)
  │     ├── monitor/         # logging, alerting, observability
  │     ├── infrastructure/  # terraform, kubernetes, provisioning
  │     ├── security/        # security hardening, access control, scanning
  ├── shared/                # reusable scripts, configs, common workflows
  ├── setup.sh               # init for usage 
  ├── README.md              # for usage
  ├── CONTRIBUTING.md        # for the devs
  ├── docs/                  # detailed docs
  

 # note: only deploy/node implemented so far
```

---

### 📦 **Available Templates**

- **Deployment**
  - `deploy/node`: Node.js Express 
  - `deploy/react`: React 
  - `deploy/python`: Python Flask
  - 'deploy/rust_actix-web': Rust Actix-Web

### 📋 **Quick Start for Users**

```bash
# 1. One-time initialization (sets up gh CLI aliases)
curl -s https://raw.githubusercontent.com/AlekOmOm/cicd-templates/main/setup.sh | bash

# 2. List available templates
gh list-cicd

# 3. Initialize a template in your project (fetches and sets up)
cd /path/to/your/project
gh init-cicd deploy/node

# 4. Set config
vim ./config/.env.config # populate with your settings

# 5. Commit and push to trigger the CI/CD pipeline
git add .
git commit -m "Add CI/CD configuration"
git push

```


### 🔍 **Detailed Usage Guide**

#### 1️⃣ **First-Time Setup**

You have two options to set up the GitHub CLI aliases:

**Option A: Using setup.sh (recommended)**
```bash
curl -s https://raw.githubusercontent.com/AlekOmOm/cicd-templates/main/setup.sh | bash
```

**Option B: Manual setup**
```bash
# Clone the template repo temporarily
git clone https://github.com/AlekOmOm/cicd-templates.git /tmp/cicd-templates

# Run the initialization script
bash /tmp/cicd-templates/templates/deploy/node/init.script.sh

# Clean up
rm -rf /tmp/cicd-templates
```

This will set up two GitHub CLI aliases:
- `gh list-cicd`: Lists all available templates
- `gh fetch-cicd`: Fetches a specific template

#### 2️⃣ **Listing Available Templates**  
```bash
gh list-cicd
```
📌 **What happens?**  
- Clones `cicd-templates` into a temporary directory
- Lists available templates by category
- Removes the temporary clone

#### 3️⃣ **Fetching a Template into Your Project**  
```bash
# Navigate to your project root
cd /path/to/your/project

# Fetch the Node.js deployment template
gh fetch-cicd deploy/node
```

📌 **What happens?**  
- Clones `cicd-templates` into a temporary directory
- Copies the specified template files into your current project
- Removes the temporary clone

#### 4️⃣ **Customizing and Applying the Template**

1. Edit the `.env.config` file with your project settings
   ```bash
   # Example: Set your app name and other configuration
   vim .env.config
   ```

2. Apply the configuration to generate deployment files
   ```bash
   # Install dotenv dependency if not already installed
   npm install --save-dev dotenv
   
   # Run the configuration script
   node scripts/apply-config.js
   ```

3. Review the generated files:
   - `.github/workflows/deploy.yml`
   - `Dockerfile`
   - `docker-compose.yml`

4. Set up GitHub repository secrets (using the GitHub web interface or CLI):
   - `SERVER_HOST`: Your deployment server hostname/IP
   - `SERVER_USER`: SSH username for deployment
   - `SSH_PRIVATE_KEY`: Your SSH private key
   - `SSH_PORT`: SSH port (usually 22)

5. Commit and push to trigger the CI/CD pipeline
   ```bash
   git add .
   git commit -m "Add CI/CD configuration"
   git push
   ```

---

### 🎯 **Why This Setup?**  
✅ **Minimal overhead** (no need for complex scripts)  
✅ **Portable & works on any machine** with `gh` installed  
✅ **Easy to maintain** since everything is inside a single repo  
✅ **Allows versioning & reuse** with shared scripts  

---
