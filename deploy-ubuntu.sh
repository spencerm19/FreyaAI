#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print status messages
print_status() {
    echo -e "${GREEN}[*] $1${NC}"
}

# Function to print error messages
print_error() {
    echo -e "${RED}[!] $1${NC}"
}

# Function to print warning messages
print_warning() {
    echo -e "${YELLOW}[!] $1${NC}"
}

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then 
    print_error "Please run as root (use sudo)"
    exit 1
fi

# Function to check command status
check_status() {
    if [ $? -eq 0 ]; then
        print_status "$1 successful"
    else
        print_error "$1 failed"
        exit 1
    fi
}

# Update system
print_status "Updating system packages..."
apt update && apt upgrade -y
check_status "System update"

# Install required packages
print_status "Installing required packages..."
apt install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    software-properties-common
check_status "Package installation"

# Install Docker
print_status "Installing Docker..."
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
check_status "Docker installation"

# Start and enable Docker service
print_status "Starting Docker service..."
systemctl start docker
systemctl enable docker
check_status "Docker service configuration"

# Install Docker Compose
print_status "Installing Docker Compose..."
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
check_status "Docker Compose installation"

# Install NVIDIA drivers
print_status "Installing NVIDIA drivers..."
ubuntu-drivers autoinstall
check_status "NVIDIA drivers installation"

# Install NVIDIA Container Toolkit
print_status "Installing NVIDIA Container Toolkit..."
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
curl -s -L https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.list | \
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
    tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
apt update
apt install -y nvidia-container-toolkit
check_status "NVIDIA Container Toolkit installation"

# Restart Docker daemon
print_status "Configuring NVIDIA Container Toolkit..."
nvidia-ctk runtime configure --runtime=docker
systemctl restart docker
check_status "Docker daemon restart"

# Create .env file if it doesn't exist
if [ ! -f .env ]; then
    print_status "Creating .env file..."
    # Generate random passwords and keys
    POSTGRES_PASSWORD=$(openssl rand -base64 32)
    N8N_ENCRYPTION_KEY=$(openssl rand -base64 32)
    N8N_JWT_SECRET=$(openssl rand -base64 32)
    WEBUI_SECRET_KEY=$(openssl rand -base64 32)

    cat > .env << EOL
# Database Configuration
POSTGRES_PASSWORD=${POSTGRES_PASSWORD}

# n8n Configuration
N8N_ENCRYPTION_KEY=${N8N_ENCRYPTION_KEY}
N8N_JWT_SECRET=${N8N_JWT_SECRET}
N8N_PORT=5678
N8N_PROTOCOL=http
N8N_HOST=0.0.0.0
N8N_EDITOR_BASE_URL=http://localhost:5678

# Storage Configuration
STORAGE_REGION=us-east-1
STORAGE_S3_BUCKET=local

# Web UI Configuration
WEBUI_PORT=3000
WEBUI_AUTH=true
WEBUI_URL=http://localhost:3000
WEBUI_SECRET_KEY=${WEBUI_SECRET_KEY}

# Flowise Configuration
FLOWISE_PORT=3001

# Qdrant Configuration
QDRANT_PORT=6333
EOL
    check_status "Environment file creation"
    print_warning "Environment file created with random secure values. Please check .env file for credentials."
fi

# Create data directories
print_status "Creating data directories..."
mkdir -p data/{n8n,ollama,qdrant,webui,flowise}
check_status "Data directory creation"

# Pull Docker images
print_status "Pulling Docker images..."
docker compose --profile gpu-nvidia pull
check_status "Docker image pull"

# Start services
print_status "Starting services..."
docker compose --profile gpu-nvidia up -d
check_status "Service startup"

# Verify NVIDIA GPU access
print_status "Verifying NVIDIA GPU access..."
docker run --rm --gpus all nvidia/cuda:12.0-base nvidia-smi
check_status "NVIDIA GPU verification"

print_status "Deployment completed successfully!"
print_status "Services should be available at:"
echo -e "${GREEN}n8n:      http://localhost:5678"
echo -e "Flowise:  http://localhost:3001"
echo -e "Web UI:   http://localhost:3000"
echo -e "Qdrant:   http://localhost:6333${NC}"

print_warning "Please save your credentials from the .env file in a secure location!"
print_warning "You may need to wait a few minutes for all services to fully initialize." 