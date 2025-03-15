# Freya AI Deployment Guide for Ubuntu

This guide will help you deploy Freya AI on your Ubuntu 24.04 Desktop computer.

## System Requirements

- Ubuntu 24.04 Desktop
- NVIDIA GPU with compatible drivers
- At least 16GB RAM
- At least 50GB free disk space
- Internet connection

## Pre-deployment Checklist

1. Ensure your system meets the minimum requirements
2. Backup any important data
3. Ensure you have root/sudo access
4. Check that ports 3000, 3001, 5678, 6333, and 11434 are available

## Deployment Steps

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd freya_ai
   ```

2. Make the deployment script executable:
   ```bash
   chmod +x deploy-ubuntu.sh
   ```

3. Run the deployment script:
   ```bash
   sudo ./deploy-ubuntu.sh
   ```

The script will:
- Update your system
- Install required packages
- Install Docker and Docker Compose
- Install NVIDIA drivers and NVIDIA Container Toolkit
- Configure environment variables
- Pull and start all required containers

## Post-deployment Steps

1. Verify all services are running:
   ```bash
   docker ps
   ```

2. Check service endpoints:
   - n8n: http://localhost:5678
   - Flowise: http://localhost:3001
   - Web UI: http://localhost:3000
   - Qdrant: http://localhost:6333
   - Ollama API: http://localhost:11434

3. Save your credentials:
   - Check the `.env` file for generated passwords and keys
   - Store these credentials in a secure location
   - Do not share these credentials

## Troubleshooting

If you encounter issues:

1. Check service logs:
   ```bash
   docker logs <container-name>
   ```

2. Verify NVIDIA GPU access:
   ```bash
   docker run --rm --gpus all nvidia/cuda:12.0-base nvidia-smi
   ```

3. Check service status:
   ```bash
   docker compose --profile gpu-nvidia ps
   ```

4. Common issues:
   - If services fail to start, try restarting Docker:
     ```bash
     sudo systemctl restart docker
     ```
   - If GPU is not detected, verify NVIDIA drivers:
     ```bash
     nvidia-smi
     ```
   - If ports are in use, check for conflicting services:
     ```bash
     sudo netstat -tulpn | grep -E '3000|3001|5678|6333|11434'
     ```

## Maintenance

1. Update services:
   ```bash
   docker compose --profile gpu-nvidia pull
   docker compose --profile gpu-nvidia up -d
   ```

2. Monitor logs:
   ```bash
   docker compose --profile gpu-nvidia logs -f
   ```

3. Backup data:
   - Database: `/var/lib/docker/volumes/freya_ai_supabase_db_data`
   - Storage: `/var/lib/docker/volumes/freya_ai_supabase_storage_data`
   - n8n workflows: `/var/lib/docker/volumes/freya_ai_n8n_storage`

## Security Notes

1. Change default passwords in `.env` file
2. Keep your system and Docker images updated
3. Monitor system resources and logs
4. Restrict access to the deployment machine
5. Use secure passwords for all services

## Support

If you need help:
1. Check the logs using `docker logs`
2. Review the troubleshooting section
3. Check GitHub issues
4. Contact support with detailed error information 