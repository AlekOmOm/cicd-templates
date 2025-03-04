### 🚀 **GitHub CI/CD Templates Setup**  

#### ✅ **Requirements**  
- a single **public GitHub repository** (`cicd-templates`) containing multiple deployment templates.  
- each template is stored inside a **separate directory** within the repo.  
- `gh` (GitHub CLI) is used to **fetch and list templates** using aliases.  
- templates should be **easy to update & maintain** without breaking existing workflows.  

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
  ├── README.md              # documentation for usage

 # note: only deploy implemented so far
```

- **each deployment template contains:**  
  - `.github/workflows/deploy.yml` (GitHub Actions)  
  - `Dockerfile` (if applicable)  
  - `docker-compose.yml` (if needed)  
  - `scripts/` (setup/config scripts)  
  - `.env.config` (environment variables)  

---

### 🔹 **Usage Workflows**  

#### 1️⃣ **Listing Available Templates**  
```sh
gh list-cicd
```
📌 **what happens?**  
- clones `cicd-templates` into `/tmp/`  
- lists available directories (templates)  
- removes the temporary clone  

#### 2️⃣ **Fetching a Template into a Project**  
```sh
gh fetch-cicd deploy-node
```
📌 **what happens?**  
- clones `cicd-templates` into `/tmp/`  
- copies `templates/deploy/node/` files into the **current project**  
- removes the temporary clone  

---

### 🔧 **Development & Maintenance Workflow**  

#### **Adding a New Template**  
1. git feature branch `git checkout -b <branch-name>`
2. `mkdir ` in `cicd-templates/templates/` and in right category fx `deploy/` or `integrate/`
3. add required files (`deploy.yml`, `Dockerfile`, etc.)  
4. commit & push changes  
5. PR   

#### **Updating a Template**  
1. branch update/<template-name> `git checkout -b update/deploy-node`
2. update
3. commit & push changes
4. PR

#### **Sharing Common Scripts**  
- use `shared/` for reusable scripts  
- templates can reference `shared/` using symbolic links or `wget`/`curl` in setup scripts  

---

### 🏗 **Setting Up the `gh` Aliases**  

#### **Alias to Fetch a Template**  
```sh
gh alias set fetch-cicd 
    '!gh repo clone your-username/cicd-templates /tmp/cicd-templates/templates 
        && cp -r /tmp/cicd-templates/templates/$1/*/ . 
        && rm -rf /tmp/cicd-templates'
```

#### **Alias to List Available Templates**  
```sh
gh alias set list-cicd 
    '!gh repo clone your-username/cicd-templates /tmp/cicd-templates 
        && ls /tmp/cicd-templates/templates/*/ 
        && rm -rf /tmp/cicd-templates'
```

---

### 🎯 **Why This Setup?**  
✅ **Minimal overhead** (no need for complex scripts)  
✅ **Portable & works on any machine** with `gh` installed  
✅ **Easy to maintain** since everything is inside a single repo  
✅ **Allows versioning & reuse** with shared scripts  

---
