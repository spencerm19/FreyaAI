param(
    [Parameter(Mandatory=$true)]
    [string]$RepoName = "freya-ai",

    [Parameter(Mandatory=$false)]
    [string]$Description = "An integrated AI development environment combining Ollama, n8n, Supabase, and more."
)

# Ensure we're in the right directory
$scriptPath = $PSScriptRoot
Set-Location $scriptPath

# Initialize git repository
Write-Host "Initializing git repository..."
git init

# Create .env.example if it doesn't exist
if (-not (Test-Path .env.example)) {
    Copy-Item .env .env.example
    (Get-Content .env.example) | ForEach-Object {
        $_ -replace "=.*", "=your-value-here"
    } | Set-Content .env.example
}

# Add all files
Write-Host "Adding files to git..."
git add .

# Initial commit
Write-Host "Creating initial commit..."
git commit -m "Initial commit"

# Create GitHub repository using GitHub CLI
Write-Host "Creating GitHub repository..."
gh repo create $RepoName --public --description $Description --source=. --remote=origin --push

Write-Host "`nRepository has been created and code has been pushed!"
Write-Host "Your repository should be available at: https://github.com/$(gh api user -q .login)/$RepoName"
Write-Host "`nNext steps:"
Write-Host "1. Visit your repository URL to verify everything was pushed correctly"
Write-Host "2. Update the repository description and topics if needed"
Write-Host "3. Consider adding branch protection rules"
Write-Host "4. Enable GitHub Actions if you plan to use CI/CD" 