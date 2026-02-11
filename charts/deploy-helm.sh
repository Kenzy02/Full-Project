#!/bin/bash

# Task Manager - Helm Deployment & Browser Script
# This script deploys all Helm charts and opens the application in a browser

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Task Manager - Helm Deployment & Browser Launcher        ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Check if we're in the charts directory
if [ ! -f "$SCRIPT_DIR/postgresql/Chart.yaml" ]; then
    echo -e "${YELLOW}Error: Could not find charts. Please run from charts directory or project root.${NC}"
    exit 1
fi

# Determine environment (dev or prod)
ENVIRONMENT="${1:-dev}"

if [ "$ENVIRONMENT" != "dev" ] && [ "$ENVIRONMENT" != "prod" ]; then
    echo -e "${YELLOW}Usage: $0 [dev|prod]${NC}"
    echo -e "${YELLOW}Defaulting to: dev${NC}"
    ENVIRONMENT="dev"
fi

echo -e "${BLUE}Environment: $ENVIRONMENT${NC}\n"

# Enable ingress by default for dev deployments.
FRONTEND_INGRESS_FLAGS=()
if [ "$ENVIRONMENT" = "dev" ]; then
    FRONTEND_INGRESS_FLAGS+=("--set" "ingress.enabled=true")
fi

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo -e "${YELLOW}Error: kubectl is not installed${NC}"
    exit 1
fi

# Check if helm is available
if ! command -v helm &> /dev/null; then
    echo -e "${YELLOW}Error: helm is not installed${NC}"
    exit 1
fi

# Check kubectl connection
echo -e "${BLUE}Checking Kubernetes connection...${NC}"
if ! kubectl cluster-info &> /dev/null; then
    echo -e "${YELLOW}Error: Cannot connect to Kubernetes cluster${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Connected to Kubernetes${NC}\n"

# Clean up old resources if they exist
echo -e "${BLUE}Cleaning up old deployments (if any)...${NC}"
helm uninstall postgresql -n pro-db 2>/dev/null || true
helm uninstall backend -n pro-be 2>/dev/null || true
helm uninstall frontend -n pro-fe 2>/dev/null || true
sleep 2

# Delete old namespaces
kubectl delete namespace pro-db pro-be pro-fe --ignore-not-found=true 2>/dev/null || true
sleep 5

echo -e "${GREEN}✓ Cleanup complete${NC}\n"

# Deploy PostgreSQL
echo -e "${BLUE}Deploying PostgreSQL...${NC}"
helm install postgresql "$SCRIPT_DIR/postgresql" \
    --values "$SCRIPT_DIR/postgresql/values-${ENVIRONMENT}.yaml" \
    -n pro-db \
    --create-namespace
echo -e "${GREEN}✓ PostgreSQL deployed${NC}\n"

# Wait for PostgreSQL
echo -e "${BLUE}Waiting for PostgreSQL to be ready...${NC}"
kubectl wait --for=condition=ready pod \
    -l app=postgresql \
    -n pro-db \
    --timeout=120s 2>/dev/null || echo -e "${YELLOW}Note: PostgreSQL still starting...${NC}"
echo -e "${GREEN}✓ PostgreSQL is running${NC}\n"

# Deploy Backend
echo -e "${BLUE}Deploying Backend...${NC}"
helm install backend "$SCRIPT_DIR/backend" \
    --values "$SCRIPT_DIR/backend/values-${ENVIRONMENT}.yaml" \
    -n pro-be \
    --create-namespace
echo -e "${GREEN}✓ Backend deployed${NC}\n"

# Wait for Backend
echo -e "${BLUE}Waiting for Backend to be ready...${NC}"
kubectl wait --for=condition=ready pod \
    -l app=backend \
    -n pro-be \
    --timeout=120s 2>/dev/null || echo -e "${YELLOW}Note: Backend still starting...${NC}"
echo -e "${GREEN}✓ Backend is running${NC}\n"

# Deploy Frontend
echo -e "${BLUE}Deploying Frontend...${NC}"
helm install frontend "$SCRIPT_DIR/frontend" \
    --values "$SCRIPT_DIR/frontend/values-${ENVIRONMENT}.yaml" \
    "${FRONTEND_INGRESS_FLAGS[@]}" \
    -n pro-fe \
    --create-namespace
echo -e "${GREEN}✓ Frontend deployed${NC}\n"

# Wait for Frontend
echo -e "${BLUE}Waiting for Frontend to be ready...${NC}"
kubectl wait --for=condition=ready pod \
    -l app=frontend \
    -n pro-fe \
    --timeout=120s 2>/dev/null || echo -e "${YELLOW}Note: Frontend still starting...${NC}"
echo -e "${GREEN}✓ Frontend is running${NC}\n"

# Kill any existing port-forward processes
pkill -f "kubectl port-forward" || true
sleep 1

# Start port forwarding in background
echo -e "${BLUE}Setting up port forwarding...${NC}"
kubectl port-forward svc/frontend-service 8080:80 -n pro-fe > /tmp/portforward.log 2>&1 &
PF_PID=$!
sleep 2

# Check if port-forward is still running
if ! kill -0 $PF_PID 2>/dev/null; then
    echo -e "${YELLOW}Error: Port forwarding failed${NC}"
    cat /tmp/portforward.log
    exit 1
fi

echo -e "${GREEN}✓ Port forwarding started (PID: $PF_PID)${NC}\n"

# Display connection info
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}✓ All services deployed successfully!${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}\n"

echo -e "${BLUE}Connection Information:${NC}"
echo -e "  Frontend:  ${GREEN}http://localhost:8080${NC}"
echo -e "  Backend:   ${GREEN}http://localhost:5000/api/tasks${NC}"
echo -e "  Swagger:   ${GREEN}http://localhost:5000/api/docs${NC}\n"

echo -e "${BLUE}Pod Status:${NC}"
kubectl get pods -n pro-db -n pro-be -n pro-fe

echo ""
echo -e "${BLUE}Helm Releases:${NC}"
helm list -n pro-db -n pro-be -n pro-fe

# Try to open browser
if command -v xdg-open &> /dev/null; then
    echo -e "\n${BLUE}Opening browser...${NC}"
    sleep 1
    xdg-open "http://localhost:8080" 2>/dev/null &
elif command -v open &> /dev/null; then
    echo -e "\n${BLUE}Opening browser...${NC}"
    sleep 1
    open "http://localhost:8080" 2>/dev/null &
else
    echo -e "\n${YELLOW}Please open http://localhost:8080 in your browser${NC}"
fi

echo -e "\n${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  To stop port forwarding: kill $PF_PID                 ║${NC}"
echo -e "${BLUE}║  To uninstall: ./uninstall-helm.sh                        ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}\n"
