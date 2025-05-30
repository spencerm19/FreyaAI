# Configure DuckDNS and update environment files
param(
    [Parameter(Mandatory=$true)]
    [string]$DuckDNSToken
)

$ErrorActionPreference = "Stop"

# Backup existing .env if it exists
if (Test-Path .env) {
    Copy-Item .env ".env.backup.$(Get-Date -Format 'yyyyMMddHHmmss')"
}

# Read the .env copy as template
$envContent = Get-Content ".env copy" -Raw

# Update the configuration
$updates = @{
    'SERVER_DOMAIN=freya.local' = 'SERVER_DOMAIN=skyewire.duckdns.org'
    'N8N_HOST=10.0.10.163' = 'N8N_HOST=0.0.0.0'
    'N8N_PROTOCOL=http' = 'N8N_PROTOCOL=https'
    'N8N_EDITOR_BASE_URL=http://${SERVER_IP}:${N8N_PORT}' = 'N8N_EDITOR_BASE_URL=https://n8n.skyewire.duckdns.org'
    'WEBUI_URL=http://${SERVER_IP}:${WEBUI_PORT}' = 'WEBUI_URL=https://webui.skyewire.duckdns.org'
    'N8N_HOSTNAME=${SERVER_DOMAIN}' = 'N8N_HOSTNAME=n8n.skyewire.duckdns.org'
    'WEBUI_HOSTNAME=${SERVER_DOMAIN}' = 'WEBUI_HOSTNAME=webui.skyewire.duckdns.org'
    'FLOWISE_HOSTNAME=${SERVER_DOMAIN}' = 'FLOWISE_HOSTNAME=flowise.skyewire.duckdns.org'
    'OLLAMA_HOSTNAME=${SERVER_DOMAIN}' = 'OLLAMA_HOSTNAME=ollama.skyewire.duckdns.org'
    'SUPABASE_HOSTNAME=${SERVER_DOMAIN}' = 'SUPABASE_HOSTNAME=storage.skyewire.duckdns.org'
    '#LETSENCRYPT_EMAIL=' = 'LETSENCRYPT_EMAIL=admin@skyewire.duckdns.org'
}

foreach ($key in $updates.Keys) {
    $envContent = $envContent -replace [regex]::Escape($key), $updates[$key]
}

# Add DuckDNS configuration
$duckDNSConfig = @"

# DuckDNS Configuration
DUCKDNS_TOKEN=$DuckDNSToken
DUCKDNS_SUBDOMAIN=skyewire
"@

$envContent += $duckDNSConfig

# Save the new .env file
$envContent | Set-Content .env -Force

Write-Host "Created new .env file with DuckDNS configuration" -ForegroundColor Green

# Update docker-compose.yml to add DuckDNS service
$composeFile = "docker-compose.yml"
$composeContent = Get-Content $composeFile -Raw

# Check if duckdns service already exists
if ($composeContent -notmatch "duckdns:") {
    $duckDNSService = @"

  # DuckDNS Dynamic DNS Updater
  duckdns:
    image: linuxserver/duckdns:latest
    container_name: duckdns
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=America/Denver
      - SUBDOMAINS=`${DUCKDNS_SUBDOMAIN}
      - TOKEN=`${DUCKDNS_TOKEN}
      - LOG_FILE=false
    restart: unless-stopped
    networks:
      - freya-net
"@

    # Add the service before the last line
    $composeContent = $composeContent -replace "`n`$", "$duckDNSService`n"
    $composeContent | Set-Content $composeFile -Force
    Write-Host "Added DuckDNS service to docker-compose.yml" -ForegroundColor Green
}

# Test DuckDNS API
$updateUrl = "https://www.duckdns.org/update?domains=skyewire&token=$DuckDNSToken&ip="
Write-Host "`nTesting DuckDNS update..."
try {
    $response = Invoke-RestMethod -Uri $updateUrl
    if ($response -eq "OK") {
        Write-Host "DuckDNS update successful!" -ForegroundColor Green
    } else {
        Write-Host "DuckDNS update failed: $response" -ForegroundColor Red
    }
} catch {
    Write-Host "Error updating DuckDNS: $_" -ForegroundColor Red
}

Write-Host "`nNext steps:"
Write-Host "1. Review the changes in .env and docker-compose.yml"
Write-Host "2. Run 'docker compose down'"
Write-Host "3. Run 'docker compose up -d'"
Write-Host "4. Check the logs with 'docker compose logs duckdns'"
Write-Host "5. Wait a few minutes for DNS propagation and SSL certificate generation" 