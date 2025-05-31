#!/bin/bash
# debug-tls.sh
# Script to help debug TLS/SSL issues with FreyaAI on Ubuntu

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}FreyaAI TLS Debug and Fix Script${NC}"
echo -e "${CYAN}--------------------------------${NC}"

# Check if the .env file exists
if [ -f ".env" ]; then
    echo -e "${GREEN}Loading environment variables from .env file...${NC}"
    
    # Load environment variables from .env file
    export $(grep -v '^#' .env | xargs)
    echo -e "${GREEN}Environment variables loaded.${NC}"
else
    echo -e "${RED}Error: .env file not found. Please create one first.${NC}"
    exit 1
fi

# Check if required tools are installed
echo -e "\n${YELLOW}Checking for required tools...${NC}"
for cmd in docker docker-compose curl dig; do
    if ! command -v $cmd &> /dev/null; then
        echo -e "${RED}Error: $cmd is not installed. Please install it first.${NC}"
        exit 1
    fi
done
echo -e "${GREEN}All required tools are installed.${NC}"

# Check DuckDNS configuration
echo -e "\n${YELLOW}Checking DuckDNS configuration...${NC}"
if [ -z "$DUCKDNS_TOKEN" ]; then
    echo -e "${RED}Error: DUCKDNS_TOKEN is not set in your .env file${NC}"
    exit 1
fi

if [ -z "$DUCKDNS_SUBDOMAIN" ]; then
    echo -e "${RED}Error: DUCKDNS_SUBDOMAIN is not set in your .env file${NC}"
    exit 1
fi

# Get current external IP
echo -e "\n${YELLOW}Getting your current external IP address...${NC}"
EXTERNAL_IP=$(curl -s https://api.ipify.org)
if [ -z "$EXTERNAL_IP" ]; then
    echo -e "${RED}Error: Could not get external IP address. Check your internet connection.${NC}"
    EXTERNAL_IP="Unknown"
else
    echo -e "${GREEN}Your external IP: $EXTERNAL_IP${NC}"
fi

# Check DuckDNS record
echo -e "\n${YELLOW}Checking DuckDNS record for $DUCKDNS_SUBDOMAIN.duckdns.org...${NC}"
DNS_RESULT=$(dig +short $DUCKDNS_SUBDOMAIN.duckdns.org A)
if [ -z "$DNS_RESULT" ]; then
    echo -e "${RED}Error: Could not resolve DNS for $DUCKDNS_SUBDOMAIN.duckdns.org${NC}"
else
    echo -e "${GREEN}DNS lookup result: $DNS_RESULT${NC}"
    
    if [ "$DNS_RESULT" = "$EXTERNAL_IP" ]; then
        echo -e "${GREEN}✓ DuckDNS record matches your external IP${NC}"
    else
        echo -e "${RED}✗ DuckDNS record ($DNS_RESULT) does not match your external IP ($EXTERNAL_IP)${NC}"
        echo -e "${YELLOW}  Attempting to update DuckDNS record...${NC}"
        
        UPDATE_RESULT=$(curl -s "https://www.duckdns.org/update?domains=$DUCKDNS_SUBDOMAIN&token=$DUCKDNS_TOKEN&ip=$EXTERNAL_IP")
        
        if [ "$UPDATE_RESULT" = "OK" ]; then
            echo -e "${GREEN}  ✓ DuckDNS record updated successfully${NC}"
        else
            echo -e "${RED}  ✗ Failed to update DuckDNS record. Result: $UPDATE_RESULT${NC}"
        fi
    fi
fi

# Check Docker containers status
echo -e "\n${YELLOW}Checking Docker containers status...${NC}"
docker-compose ps

# Check if Caddy container is running
CADDY_RUNNING=$(docker-compose ps | grep caddy | grep Up)
if [ -z "$CADDY_RUNNING" ]; then
    echo -e "${RED}✗ Caddy container is not running${NC}"
else
    echo -e "${GREEN}✓ Caddy container is running${NC}"
fi

# Offer to fix common issues
echo -e "\n${YELLOW}Would you like to attempt to fix TLS issues? (y/n)${NC}"
read -r FIX_RESPONSE

if [ "$FIX_RESPONSE" = "y" ]; then
    echo -e "\n${GREEN}Applying fixes...${NC}"
    
    # 1. Check if Caddy is properly configured
    echo -e "${YELLOW}1. Checking Caddy configuration...${NC}"
    grep -q "dns duckdns" Caddyfile
    if [ $? -ne 0 ]; then
        echo -e "${RED}  ✗ DuckDNS DNS configuration not found in Caddyfile${NC}"
    else
        echo -e "${GREEN}  ✓ DuckDNS DNS configuration found in Caddyfile${NC}"
    fi
    
    # 2. Rebuild the Caddy container
    echo -e "${YELLOW}2. Rebuilding the Caddy container...${NC}"
    docker-compose build --no-cache caddy
    
    # 3. Restart the containers
    echo -e "${YELLOW}3. Restarting containers...${NC}"
    docker-compose down
    docker-compose up -d
    
    # 4. Check Caddy logs
    echo -e "${YELLOW}4. Checking Caddy logs (press Ctrl+C to exit)...${NC}"
    echo -e "${YELLOW}   This may take a minute as Caddy obtains new certificates...${NC}"
    docker-compose logs -f caddy
else
    echo -e "${YELLOW}No fixes applied. You can manually rebuild and restart the containers.${NC}"
fi

echo -e "\n${CYAN}TLS Debug completed.${NC}" 