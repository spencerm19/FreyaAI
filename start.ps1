param (
    [Parameter(Mandatory=$false)]
    [ValidateSet("cpu", "gpu-nvidia", "gpu-amd")]
    [string]$Profile = "cpu"
)

Write-Host "Starting Freya AI with profile: $Profile"

# Check if .env file exists
if (-not (Test-Path .env)) {
    Write-Host "Error: .env file not found. Please create one from the .env.example template." -ForegroundColor Red
    exit 1
}

# Stop any running containers
Write-Host "Stopping any running containers..."
docker compose down

# Start services with selected profile
Write-Host "Starting services with $Profile profile..."
docker compose --profile $Profile up -d

Write-Host "Services are starting up. You can access them at:"
Write-Host "- n8n: http://localhost:5678"
Write-Host "- Open WebUI: http://localhost:3000"
Write-Host "- Flowise: http://localhost:3001"
Write-Host "- Qdrant: http://localhost:6333"
Write-Host "- Supabase PostgreSQL: localhost:5432"

Write-Host "`nTo view logs, use: docker compose logs -f"
Write-Host "To stop services, use: docker compose down" 