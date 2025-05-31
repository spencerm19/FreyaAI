#!/bin/bash
# rebuild-caddy.sh
# Script to rebuild and restart the Caddy container for FreyaAI

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}FreyaAI Caddy Rebuild Script${NC}"
echo -e "${CYAN}---------------------------${NC}"

# Stop Caddy container if running
echo -e "${YELLOW}Stopping Caddy container if running...${NC}"
docker-compose stop caddy
docker-compose rm -f caddy

# Rebuild Caddy image
echo -e "${YELLOW}Rebuilding Caddy container...${NC}"
docker-compose build --no-cache caddy

# Start Caddy container
echo -e "${YELLOW}Starting Caddy container...${NC}"
docker-compose up -d caddy

# Check if Caddy is running
echo -e "${YELLOW}Checking if Caddy is running...${NC}"
sleep 5
CADDY_RUNNING=$(docker-compose ps | grep caddy | grep Up)
if [ -z "$CADDY_RUNNING" ]; then
    echo -e "${RED}✗ Caddy container is not running${NC}"
    echo -e "${YELLOW}Checking Caddy logs...${NC}"
    docker-compose logs caddy
else
    echo -e "${GREEN}✓ Caddy container is running${NC}"
    echo -e "${YELLOW}Checking Caddy logs (press Ctrl+C to exit)...${NC}"
    docker-compose logs -f caddy
fi

echo -e "\n${CYAN}Caddy rebuild completed.${NC}" 