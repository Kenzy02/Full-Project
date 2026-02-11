#!/bin/bash

# Task Manager - Helm Uninstall Script
# This script removes all Helm deployments and namespaces

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${RED}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${RED}║  Task Manager - Helm Uninstall                            ║${NC}"
echo -e "${RED}╚════════════════════════════════════════════════════════════╝${NC}"

# Ask for confirmation
read -p "Are you sure you want to uninstall all deployments? (yes/no): " CONFIRM
if [ "$CONFIRM" != "yes" ]; then
    echo -e "${YELLOW}Cancelled.${NC}"
    exit 0
fi

# Kill port forwarding if running
echo -e "${BLUE}Stopping port forwarding...${NC}"
pkill -f "kubectl port-forward" || true
sleep 1
echo -e "${GREEN}✓ Port forwarding stopped${NC}\n"

# Uninstall Helm releases
echo -e "${BLUE}Uninstalling Helm releases...${NC}"

echo -e "${YELLOW}Uninstalling frontend...${NC}"
helm uninstall frontend -n pro-fe 2>/dev/null || echo "  (not found)"

echo -e "${YELLOW}Uninstalling backend...${NC}"
helm uninstall backend -n pro-be 2>/dev/null || echo "  (not found)"

echo -e "${YELLOW}Uninstalling postgresql...${NC}"
helm uninstall postgresql -n pro-db 2>/dev/null || echo "  (not found)"

sleep 3
echo -e "${GREEN}✓ Helm releases uninstalled${NC}\n"

# Delete namespaces
echo -e "${BLUE}Deleting namespaces...${NC}"
kubectl delete namespace pro-fe pro-be pro-db --ignore-not-found=true --grace-period=30
sleep 5
echo -e "${GREEN}✓ Namespaces deleted${NC}\n"

echo -e "${RED}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}✓ Uninstall complete!${NC}"
echo -e "${RED}╚════════════════════════════════════════════════════════════╝${NC}\n"
