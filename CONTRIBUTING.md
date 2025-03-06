

### ✅ **Requirements**  
- A single **public GitHub repository** (`cicd-templates`) containing multiple deployment templates
- Each template is stored inside a **separate directory** within the repo
- `gh` (GitHub CLI) is used to **fetch and list templates** using aliases
- Templates should be **easy to update & maintain** without breaking existing workflows


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
