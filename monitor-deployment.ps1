#!/usr/bin/env pwsh

function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

function Test-ServiceHealth {
    param(
        [string]$ServiceName,
        [string]$Url
    )
    try {
        $response = Invoke-WebRequest -Uri $Url -Method HEAD -TimeoutSec 5
        if ($response.StatusCode -eq 200) {
            Write-ColorOutput "[✓] $ServiceName is healthy (Status: $($response.StatusCode))" "Green"
            return $true
        } else {
            Write-ColorOutput "[!] $ServiceName returned status code: $($response.StatusCode)" "Yellow"
            return $false
        }
    } catch {
        Write-ColorOutput "[✗] $ServiceName is not responding: $($_.Exception.Message)" "Red"
        return $false
    }
}

function Get-ContainerStats {
    param(
        [string]$ContainerName
    )
    try {
        $statsCmd = "docker stats --no-stream $ContainerName | Select-Object -Skip 1"
        $stats = Invoke-Expression $statsCmd
        if ($stats) {
            Write-ColorOutput "`nContainer: $ContainerName" "Cyan"
            Write-ColorOutput "Stats: $stats" "White"
        }
    } catch {
        Write-ColorOutput "Failed to get stats for $ContainerName: $($_.Exception.Message)" "Red"
    }
}

# Monitor deployment
Write-ColorOutput "`n=== Monitoring Deployment ===" "Cyan"

# Check Docker services
Write-ColorOutput "`nChecking Docker services..." "Cyan"
$services = (docker compose ps --quiet).Split("`n") | Where-Object { $_ }
foreach ($service in $services) {
    $status = (docker inspect $service | ConvertFrom-Json).State.Status
    $name = (docker inspect $service | ConvertFrom-Json).Name.TrimStart('/')
    if ($status -eq "running") {
        Write-ColorOutput "[✓] $name is running" "Green"
    } else {
        Write-ColorOutput "[✗] $name is $status" "Red"
    }
}

# Check service health
Write-ColorOutput "`nChecking service health..." "Cyan"
Test-ServiceHealth "Grafana" "http://localhost:3002"
Test-ServiceHealth "Prometheus" "http://localhost:9090"
Test-ServiceHealth "Loki" "http://localhost:3100"
Test-ServiceHealth "cAdvisor" "http://localhost:8080"
Test-ServiceHealth "n8n" "http://localhost:5678"
Test-ServiceHealth "Flowise" "http://localhost:3001"
Test-ServiceHealth "Web UI" "http://localhost:3000"
Test-ServiceHealth "Qdrant" "http://localhost:6333"
Test-ServiceHealth "Ollama" "http://localhost:11434"

# Get resource usage
Write-ColorOutput "`nChecking resource usage..." "Cyan"
$containers = @("prometheus", "grafana", "loki", "cadvisor", "n8n", "qdrant", "flowise", "open-webui")
foreach ($container in $containers) {
    Get-ContainerStats $container
}

Write-ColorOutput "`n=== Monitoring URLs ===" "Cyan"
Write-ColorOutput "Grafana: http://localhost:3002 (admin/admin by default)" "White"
Write-ColorOutput "Prometheus: http://localhost:9090" "White"
Write-ColorOutput "cAdvisor: http://localhost:8080" "White"
Write-ColorOutput "Loki: http://localhost:3100" "White"

Write-ColorOutput "`n=== Logs ===" "Cyan"
Write-ColorOutput "To view logs for a specific service:" "White"
Write-ColorOutput "docker compose logs [service-name]" "Yellow"
Write-ColorOutput "For continuous monitoring:" "White"
Write-ColorOutput "docker compose logs -f [service-name]" "Yellow" 