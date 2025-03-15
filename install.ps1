# Helper Functions
function Test-CommandExists {
    param ($command)
    $oldPreference = $ErrorActionPreference
    $ErrorActionPreference = 'stop'
    try {
        if (Get-Command $command) { return $true }
    } catch {
        return $false
    } finally {
        $ErrorActionPreference = $oldPreference
    }
}

function Get-SecureRandomString {
    param (
        [int]$length = 32
    )
    $random = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    $bytes = New-Object byte[] $length
    $random.GetBytes($bytes)
    return [Convert]::ToBase64String($bytes)
}

Write-Host "Freya AI Installation Script"
Write-Host "==========================="
Write-Host

# Ensure we're in the right directory
$scriptPath = $PSScriptRoot
Set-Location $scriptPath

# Check for Docker Desktop
if (-not (Test-CommandExists "docker")) {
    Write-Host "Docker Desktop is not installed."
    Write-Host "Please install Docker Desktop from: https://www.docker.com/products/docker-desktop"
    Write-Host "After installing Docker Desktop:"
    Write-Host "1. Restart your computer"
    Write-Host "2. Run Docker Desktop"
    Write-Host "3. Run this script again"
    Pause
    Exit
}

# Check if Docker is running
$dockerRunning = (docker info 2>$null)
if (-not $dockerRunning) {
    Write-Host "Starting Docker Desktop..."
    Start-Process "C:\Program Files\Docker\Docker\Docker Desktop.exe"
    Write-Host "Waiting for Docker to start (this may take a few minutes)..."
    $attempts = 0
    do {
        Start-Sleep -Seconds 5
        $dockerRunning = (docker info 2>$null)
        $attempts++
        Write-Host "." -NoNewline
        if ($attempts -gt 24) { # 2 minutes timeout
            Write-Host "`nDocker Desktop is taking too long to start. Please:"
            Write-Host "1. Ensure Docker Desktop is running"
            Write-Host "2. Run this script again"
            Pause
            Exit
        }
    } while (-not $dockerRunning)
    Write-Host "`nDocker Desktop is ready!"
}

# Create .env file if it doesn't exist
if (-not (Test-Path .env)) {
    Write-Host "Creating .env file..."
    $envContent = @"
# Server Configuration
SERVER_IP=localhost
SERVER_DOMAIN=localhost

# Database Configuration
POSTGRES_PASSWORD=$(Get-SecureRandomString)

# n8n Configuration
N8N_HOST=0.0.0.0
N8N_PORT=5678
N8N_PROTOCOL=http
N8N_EDITOR_BASE_URL=http://localhost:5678
N8N_ENCRYPTION_KEY=$(Get-SecureRandomString)
N8N_JWT_SECRET=$(Get-SecureRandomString)

# Storage Configuration
STORAGE_REGION=us-east-1
STORAGE_S3_BUCKET=freya-storage

# Web UI Configuration
WEBUI_PORT=3000
WEBUI_URL=http://localhost:3000
WEBUI_AUTH=true
WEBUI_SECRET_KEY=$(Get-SecureRandomString)

# Service Ports
QDRANT_PORT=6333
FLOWISE_PORT=3001
OLLAMA_PORT=11434

# Domain Configuration
N8N_HOSTNAME=localhost
WEBUI_HOSTNAME=localhost
FLOWISE_HOSTNAME=localhost
OLLAMA_HOSTNAME=localhost
SUPABASE_HOSTNAME=localhost
LETSENCRYPT_EMAIL=internal

# Ollama Configuration
OLLAMA_MODELS=qwen2.5:7b-instruct-q4_K_M,nomic-embed-text,smallthinker,llama3-chatqa,sadiq-bd/llama3.2-1b-uncensored
"@
    $envContent | Out-File -FilePath .env -Encoding UTF8
    Write-Host "Environment file created successfully!"
}

# Create shared directory if it doesn't exist
if (-not (Test-Path shared)) {
    Write-Host "Creating shared directory..."
    New-Item -ItemType Directory -Path shared
}

# Check for NVIDIA GPU
$hasNvidia = $false
try {
    $gpu = Get-WmiObject Win32_VideoController | Where-Object { $_.Name -match "NVIDIA" }
    if ($gpu) {
        $hasNvidia = $true
        Write-Host "NVIDIA GPU detected: $($gpu.Name)"
    }
} catch {
    Write-Host "No NVIDIA GPU detected, using CPU profile"
}

# Start the services
Write-Host "`nStarting Freya AI services..."
if ($hasNvidia) {
    Write-Host "Using NVIDIA GPU profile..."
    docker compose --profile gpu-nvidia up -d
} else {
    Write-Host "Using CPU profile..."
    docker compose --profile cpu up -d
}

Write-Host "`nFreya AI is now being installed and started!"
Write-Host "Please wait a few minutes for all services to initialize..."
Write-Host "`nOnce everything is ready, you can access the following services:"
Write-Host "- Open WebUI: http://localhost:3000"
Write-Host "- n8n: http://localhost:5678"
Write-Host "- Flowise: http://localhost:3001"
Write-Host "- Qdrant: http://localhost:6333"
Write-Host "`nThe installation process is complete! You can monitor the status using:"
Write-Host "docker compose ps"
Write-Host "`nPress any key to exit..."
Pause 