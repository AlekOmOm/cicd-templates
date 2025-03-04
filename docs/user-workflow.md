you're right - i missed the core issue. as a user trying to use the template repo, you wouldn't have access to the scripts yet.

let's think through the workflow from first principles:

## conceptual workflow for template users

1. user has their own project (pensum_run)
2. user wants to add cicd configuration
3. user needs a way to discover and fetch templates from cicd-templates repo

the key problems:
- bootstrap problem: can't use the aliases until you have them, but need the repo content to set them up
- discoverability: how does a user know what templates exist?
- simplicity: minimize manual steps required

## proposed user workflow

1. **initialize access to templates** (one-time setup)
   ```bash
   # clone the cicd-templates repo temporarily
   git clone https://github.com/AlekOmOm/cicd-templates.git /tmp/cicd-templates
   
   # run the initialization script
   bash /tmp/cicd-templates/templates/deploy/node/init.script.sh
   
   # cleanup
   rm -rf /tmp/cicd-templates
   ```

2. **browse available templates**
   ```bash
   gh list-cicd
   ```

3. **fetch and apply a template**
   ```bash
   # in the project root
   gh fetch-cicd deploy/node
   
   # customize configuration
   vim .env.config
   
   # apply configuration
   npm install --save-dev dotenv
   node scripts/apply-config.js
   ```



# workflow for a first-time user:

## step 1: one-time setup (initialize access to templates)
```bash
# option a: using curl (easiest)
curl -s https://raw.githubusercontent.com/YOUR-USERNAME/cicd-templates/main/setup.sh | bash

# option b: manual setup
git clone https://github.com/YOUR-USERNAME/cicd-templates.git /tmp/cicd-templates
bash /tmp/cicd-templates/templates/deploy/node/init.script.sh
rm -rf /tmp/cicd-templates
```

## step 2: list available templates
```bash
gh list-cicd
```

## step 3: fetch a template into your project
```bash
# navigate to your project's root directory
cd /path/to/pensum_run

# fetch the node.js deployment template
gh fetch-cicd deploy/node
```

## step 4: customize and apply the template
```bash
# edit configuration
vim .env.config  # set APP_NAME=pensum_run, etc.

# install dotenv if needed
npm install --save-dev dotenv

# apply configuration
node scripts/apply-config.js
```

## step 5: set up secrets and push
```bash
# set up github secrets via web ui or cli
gh secret set SERVER_HOST --body "your-server-host"
gh secret set SERVER_USER --body "your-server-user"
gh secret set SSH_PRIVATE_KEY --body "$(cat ~/.ssh/id_rsa)"
gh secret set SSH_PORT --body "22"

# commit and push
git add .
git commit -m "Add CI/CD configuration"
git push
```

this workflow addresses the bootstrap problem and simplifies the process for users. the setup.sh script eliminates the need for manual configuration and provides a one-line command to get started.
