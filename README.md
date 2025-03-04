### 🚀 **GitHub CI/CD Templates Setup**  

#### ✅ **Requirements**  
- A single **public GitHub repository** (`cicd-templates`) containing multiple deployment templates
- Each template is stored inside a **separate directory** within the repo
- `gh` (GitHub CLI) is used to **fetch and list templates** using aliases
- Templates should be **easy to update & maintain** without breaking existing workflows

---

### 📋 **Quick Start for Users**

```bash
# 1. One-time initialization (sets up gh CLI aliases)
curl -s https://raw.githubusercontent.com/YOUR-USERNAME/cicd-templates/main/setup.sh | bash

# 2. List available templates
gh list-cicd

# 3. Fetch a template into your project
cd /path/to/your/project
gh fetch-cicd deploy/node

# 4. Customize and apply the template
# Edit .env.config with your settings
npm install --save-dev dotenv  # if not already installed
node scripts/apply-config.js
```

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
  ├── setup.sh               # initialization script for users
  ├── README.md              # documentation for usage

 # note: only deploy implemented so far
```

---

### 🔍 **Detailed Usage Guide**

#### 1️⃣ **First-Time Setup**

You have two options to set up the GitHub CLI aliases:

**Option A: Using setup.sh (recommended)**
```bash
curl -s https://raw.githubusercontent.com/YOUR-USERNAME/cicd-templates/main/setup.sh | bash
```

**Option B: Manual setup**
```bash
# Clone the template repo temporarily
git clone https://github.com/YOUR-USERNAME/cicd-templates.git /tmp/cicd-templates

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

### 🔧 **Development & Maintenance Workflow**  

#### **Adding a New Template**  
1. Create a feature branch: `git checkout -b <branch-name>`
2. Create directory in the appropriate category: `mkdir -p templates/deploy/new-template`
3. Add required files (`deploy.yml`, `Dockerfile`, etc.)
4. Commit & push changes
5. Submit a PR

#### **Updating a Template**  
1. Create an update branch: `git checkout -b update/deploy-node`
2. Make your updates
3. Commit & push changes
4. Submit a PR

#### **Sharing Common Scripts**  
- Use `shared/` for reusable scripts  
- Templates can reference `shared/` using symbolic links or `wget`/`curl` in setup scripts  

---

### 🎯 **Why This Setup?**  
✅ **Minimal overhead** (no need for complex scripts)  
✅ **Portable & works on any machine** with `gh` installed  
✅ **Easy to maintain** since everything is inside a single repo  
✅ **Allows versioning & reuse** with shared scripts  

---
