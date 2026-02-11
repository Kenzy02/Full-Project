#!/bin/bash
# Quick Deploy Script for Task Manager Kubernetes Application
# This script provides a simple way to deploy the entire application

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}════════════════════════════════════════════${NC}"
echo -e "${GREEN}  Task Manager - Kubernetes Deployment${NC}"
echo -e "${GREEN}════════════════════════════════════════════${NC}"
echo ""

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}Error: kubectl is not installed${NC}"
    exit 1
fi

# Check if cluster is accessible
if ! kubectl cluster-info &> /dev/null; then
    echo -e "${RED}Error: Cannot access Kubernetes cluster${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Kubernetes cluster is accessible${NC}"
echo ""

# Deploy Database
echo -e "${YELLOW}[1/4] Deploying Database...${NC}"
kubectl apply -f database/
echo -e "${GREEN}✓ Database manifests applied${NC}"
echo -e "${YELLOW}Waiting for PostgreSQL to be ready...${NC}"
kubectl wait --for=condition=ready pod -l app=postgresql -n pro-db --timeout=180s || echo "Warning: Database may still be starting"
echo ""

# Deploy Backend
echo -e "${YELLOW}[2/4] Deploying Backend API...${NC}"
kubectl apply -f backend/
echo -e "${GREEN}✓ Backend manifests applied${NC}"
echo -e "${YELLOW}Waiting for Backend to be ready...${NC}"
kubectl wait --for=condition=ready pod -l app=backend -n pro-be --timeout=180s || echo "Warning: Backend may still be starting"
echo ""

# Deploy Frontend
echo -e "${YELLOW}[3/4] Deploying Frontend...${NC}"
kubectl apply -f frontend/
echo -e "${GREEN}✓ Frontend manifests applied${NC}"
echo -e "${YELLOW}Waiting for Frontend to be ready...${NC}"
kubectl wait --for=condition=ready pod -l app=frontend -n pro-fe --timeout=180s || echo "Warning: Frontend may still be starting"
echo ""

# Deploy Ingress
echo -e "${YELLOW}[4/4] Deploying Ingress...${NC}"
kubectl apply -f ingress.yaml
echo -e "${GREEN}✓ Ingress manifests applied${NC}"
echo ""

# Show status
echo -e "${GREEN}════════════════════════════════════════════${NC}"
echo -e "${GREEN}  Deployment Complete!${NC}"
echo -e "${GREEN}════════════════════════════════════════════${NC}"
echo ""

echo -e "${YELLOW}Pod Status:${NC}"
echo -e "${YELLOW}Database:${NC}"
kubectl get pods -n pro-db
echo ""
echo -e "${YELLOW}Backend:${NC}"
kubectl get pods -n pro-be
echo ""
echo -e "${YELLOW}Frontend:${NC}"
kubectl get pods -n pro-fe
echo ""

echo -e "${YELLOW}Services:${NC}"
kubectl get svc -n pro-db -n pro-be -n pro-fe
echo ""

echo -e "${YELLOW}Ingress:${NC}"
kubectl get ingress -n pro-fe
echo ""

echo -e "${GREEN}Application should be accessible at:${NC}"
echo -e "${GREEN}  http://localhost${NC}"
echo ""
echo -e "${YELLOW}For Minikube users, run:${NC}"
echo -e "${YELLOW}  minikube tunnel${NC}"
echo ""
