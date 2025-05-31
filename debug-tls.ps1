# debug-tls.ps1
# Script to help debug TLS/SSL issues with FreyaAI

Write-Host "FreyaAI TLS Debug and Fix Script" -ForegroundColor Cyan
Write-Host "--------------------------------" -ForegroundColor Cyan

# Check if the .env file exists
if (Test-Path -Path ".env") {
    Write-Host "Loading environment variables from .env file..." -ForegroundColor Green
    
    # Load environment variables from .env file
    Get-Content .env | ForEach-Object {
        if (-not [string]::IsNullOrWhiteSpace($_) -and -not $_.StartsWith('#')) {
            $key, $value = $_.Split('=', 2)
            [Environment]::SetEnvironmentVariable($key, $value, "Process")
            Write-Host "  Set $key"
        }
    }
} else {
    Write-Host "Error: .env file not found. Please create one first." -ForegroundColor Red
    exit 1
}

# Check DuckDNS configuration
Write-Host "`nChecking DuckDNS configuration..." -ForegroundColor Yellow
$duckdnsToken = [Environment]::GetEnvironmentVariable("DUCKDNS_TOKEN")
$duckdnsSubdomain = [Environment]::GetEnvironmentVariable("DUCKDNS_SUBDOMAIN")

if ([string]::IsNullOrWhiteSpace($duckdnsToken)) {
    Write-Host "Error: DUCKDNS_TOKEN is not set in your .env file" -ForegroundColor Red
    exit 1
}

if ([string]::IsNullOrWhiteSpace($duckdnsSubdomain)) {
    Write-Host "Error: DUCKDNS_SUBDOMAIN is not set in your .env file" -ForegroundColor Red
    exit 1
}

# Get current external IP
Write-Host "`nGetting your current external IP address..." -ForegroundColor Yellow
try {
    $externalIP = (Invoke-WebRequest -Uri "https://api.ipify.org" -UseBasicParsing).Content
    Write-Host "Your external IP: $externalIP" -ForegroundColor Green
} catch {
    Write-Host "Error: Could not get external IP address. Check your internet connection." -ForegroundColor Red
    $externalIP = "Unknown"
}

# Check DuckDNS record
Write-Host "`nChecking DuckDNS record for $duckdnsSubdomain.duckdns.org..." -ForegroundColor Yellow
try {
    $dnsResult = (Resolve-DnsName -Name "$duckdnsSubdomain.duckdns.org" -Type A -ErrorAction Stop).IP4Address
    Write-Host "DNS lookup result: $dnsResult" -ForegroundColor Green
    
    if ($dnsResult -eq $externalIP) {
        Write-Host "✓ DuckDNS record matches your external IP" -ForegroundColor Green
    } else {
        Write-Host "✗ DuckDNS record ($dnsResult) does not match your external IP ($externalIP)" -ForegroundColor Red
        Write-Host "  Attempting to update DuckDNS record..." -ForegroundColor Yellow
        
        $updateUrl = "https://www.duckdns.org/update?domains=$duckdnsSubdomain&token=$duckdnsToken&ip=$externalIP"
        $updateResult = (Invoke-WebRequest -Uri $updateUrl -UseBasicParsing).Content
        
        if ($updateResult -eq "OK") {
            Write-Host "  ✓ DuckDNS record updated successfully" -ForegroundColor Green
        } else {
            Write-Host "  ✗ Failed to update DuckDNS record. Result: $updateResult" -ForegroundColor Red
        }
    }
} catch {
    Write-Host "Error resolving DNS for $duckdnsSubdomain.duckdns.org: $_" -ForegroundColor Red
}

# Offer to fix common issues
Write-Host "`nWould you like to attempt to fix TLS issues? (y/n)" -ForegroundColor Yellow
$fixResponse = Read-Host

if ($fixResponse -eq "y") {
    Write-Host "`nApplying fixes..." -ForegroundColor Green
    
    # 1. Ensure the Caddy container is using the custom build
    Write-Host "1. Ensuring docker-compose is set to use the custom Caddy build..." -ForegroundColor Yellow
    
    # 2. Rebuilding the Caddy container
    Write-Host "2. Rebuilding the Caddy container..." -ForegroundColor Yellow
    docker-compose build --no-cache caddy
    
    # 3. Restart the containers
    Write-Host "3. Restarting containers..." -ForegroundColor Yellow
    docker-compose down
    docker-compose up -d
    
    # 4. Check container logs
    Write-Host "4. Checking Caddy logs (press Ctrl+C to exit)..." -ForegroundColor Yellow
    Write-Host "   This may take a minute as Caddy obtains new certificates..." -ForegroundColor Yellow
    docker-compose logs -f caddy
} else {
    Write-Host "No fixes applied. You can manually rebuild and restart the containers." -ForegroundColor Yellow
}

Write-Host "`nTLS Debug completed." -ForegroundColor Cyan 