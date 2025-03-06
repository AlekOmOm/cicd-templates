# Setup script for cicd-templates in PowerShell
Write-Host "===== GitHub CI/CD Templates Setup =====" -ForegroundColor Yellow

# Check if GitHub CLI is installed
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    Write-Host "GitHub CLI (gh) is not installed." -ForegroundColor Red
    Write-Host "Please install it from: https://cli.github.com/"
    Write-Host "`nInstallation instructions:"
    Write-Host "  - Windows: winget install --id GitHub.cli"
    exit 1
} else {
    Write-Host "✓ GitHub CLI is installed" -ForegroundColor Green
}

# Check GitHub authentication
$authStatus = gh auth status 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "You need to authenticate with GitHub CLI" -ForegroundColor Yellow
    Write-Host "Running: gh auth login"
    gh auth login
} else {
    Write-Host "✓ GitHub CLI is authenticated" -ForegroundColor Green
}

# Default repository settings
$defaultUsername = "AlekOmOm"
$defaultRepo = "cicd-templates"
$githubUsername = $defaultUsername
$repoName = $defaultRepo

# Check repository access
function Test-RepoAccess {
    param (
        [string]$username,
        [string]$repo
    )
    
    $repoCheck = gh repo view "$username/$repo" 2>&1
    return $LASTEXITCODE -eq 0
}

# Try default repository
if (Test-RepoAccess -username $defaultUsername -repo $defaultRepo) {
    Write-Host "✓ Using repository: $defaultUsername/$defaultRepo" -ForegroundColor Green
    $githubUsername = $defaultUsername
    $repoName = $defaultRepo
} else {
    # Try to get current user
    $currentUser = (gh api user | ConvertFrom-Json).login
    
    if ($currentUser -and (Test-RepoAccess -username $currentUser -repo $defaultRepo)) {
        Write-Host "✓ Found your fork: $currentUser/$defaultRepo" -ForegroundColor Green
        $githubUsername = $currentUser
        $repoName = $defaultRepo
    } else {
        # Prompt for manual entry
        Write-Host "Unable to automatically detect the repository." -ForegroundColor Yellow
        
        $inputUsername = Read-Host "Enter GitHub username for cicd-templates repo (default: $defaultUsername)"
        if ($inputUsername) { $githubUsername = $inputUsername }
        
        $inputRepo = Read-Host "Enter repository name (default: $defaultRepo)"
        if ($inputRepo) { $repoName = $inputRepo }
        
        if (-not (Test-RepoAccess -username $githubUsername -repo $repoName)) {
            Write-Host "Repository $githubUsername/$repoName is not accessible." -ForegroundColor Red
            Write-Host "Please check if:"
            Write-Host "1. The repository exists"
            Write-Host "2. The repository is public"
            Write-Host "3. You have the correct permissions"
            exit 1
        }
    }
}

Write-Host "`nSetting up GitHub CLI aliases..." -ForegroundColor Yellow

# Create the aliases
$initAlias = "!f() { echo ""Initializing template: `$1""; gh fetch-cicd `$1 && if [ -f ""./CD-*.template-setup.sh"" ]; then chmod +x ./CD-*.template-setup.sh && ./CD-*.template-setup.sh; fi; }; f"
$fetchAlias = "!f() { echo ""Fetching template: `$1""; TMP_DIR=`$(mktemp -d); gh repo clone $githubUsername/$repoName ""`$TMP_DIR"" > /dev/null 2>&1 && cp -r ""`$TMP_DIR/templates/`$1/""* . 2>/dev/null; RET=`$?; rm -rf ""`$TMP_DIR""; if [ `$RET -ne 0 ]; then echo ""Template `$1 not found or error occurred""; exit 1; else echo ""Template `$1 copied successfully""; fi; }; f"
$listAlias = "!f() { echo ""Available templates:""; TMP_DIR=`$(mktemp -d); gh repo clone $githubUsername/$repoName ""`$TMP_DIR"" > /dev/null 2>&1 && find ""`$TMP_DIR/templates"" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | while read dir; do echo ""`n→ `$dir""; ls -d ""`$TMP_DIR/templates/`$dir""/* 2>/dev/null | grep -v ""\.git"" | xargs -n1 basename 2>/dev/null | sed 's/^/  ✓ /'; done; rm -rf ""`$TMP_DIR""; }; f"

# Delete existing aliases if they exist
$aliases = gh alias list
if ($aliases -match "init-cicd") {
    Write-Host "Updating existing init-cicd alias" -ForegroundColor Yellow
    gh alias delete init-cicd | Out-Null
}
if ($aliases -match "fetch-cicd") {
    Write-Host "Updating existing fetch-cicd alias" -ForegroundColor Yellow
    gh alias delete fetch-cicd | Out-Null
}
if ($aliases -match "list-cicd") {
    Write-Host "Updating existing list-cicd alias" -ForegroundColor Yellow
    gh alias delete list-cicd | Out-Null
}

# Set the aliases
gh alias set init-cicd $initAlias
gh alias set fetch-cicd $fetchAlias
gh alias set list-cicd $listAlias

Write-Host "✓ GitHub CLI aliases set up successfully" -ForegroundColor Green

# Display usage examples
Write-Host "`nSetup complete! You can now use the following commands:" -ForegroundColor Green

Write-Host "`nList available templates:" -ForegroundColor Yellow
Write-Host "  gh list-cicd"

Write-Host "`nFetch a template into your project:" -ForegroundColor Yellow
Write-Host "  cd /path/to/your/project"
Write-Host "  gh fetch-cicd deploy/node"

Write-Host "`nAfter fetching a template:" -ForegroundColor Yellow
Write-Host "  1. Customize config/.env.config with your project settings"
Write-Host "  2. Run 'npm install --save-dev dotenv' (if needed)"
Write-Host "  3. Apply configuration with 'node scripts/apply-config.js'"

Write-Host "`nRepository used for templates:" -ForegroundColor Yellow
Write-Host "  https://github.com/$githubUsername/$repoName"

Write-Host "`n✓ Setup completed successfully!" -ForegroundColor Green
