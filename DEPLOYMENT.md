# Deployment Guide

Complete step-by-step guide for deploying the full-stack microservices application to Kubernetes.

---

## Prerequisites

### Required Tools
Install the following tools before proceeding:

```bash
# Helm 3+
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
helm version

# kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl && sudo mv kubectl /usr/local/bin/
kubectl version --client

# Docker
# Follow: https://docs.docker.com/engine/install/

# Terraform (for infrastructure)
wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
unzip terraform_1.6.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/
terraform version

# Cloud CLI (choose based on your provider)
# AWS CLI: https://aws.amazon.com/cli/
# Azure CLI: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli
# GCloud CLI: https://cloud.google.com/sdk/docs/install
```

### Verify Installation
```bash
helm version
kubectl version --client
docker --version
terraform --version
```

---

## Local Testing

### Step 1: Verify Components Independently

**Test Backend:**
```bash
cd backend

# Install dependencies
pip install -r requirements.txt

# Set environment variables
export DATABASE_URL="postgresql://postgres:postgres@localhost:5433/microservices_db"
export FLASK_ENV=development

# Run the application
python app.py

# Test in another terminal
curl http://localhost:5001/health
```

**Test Frontend:**
```bash
cd frontend

# Ensure required files exist
# - public/index.html
# - public/manifest.json
# - public/robots.txt
# - package-lock.json (run 'npm install' to generate if missing)

# Install dependencies
npm install

# Set environment variable
export REACT_APP_API_URL=http://localhost:5001/api

# Run the application
npm start

# Open http://localhost:3000 in browser
```

### Step 2: Docker Compose Testing

**Build and run all components:**
```bash
# From project root
docker-compose up --build

# Verify services are running
docker-compose ps

# Check logs
docker-compose logs -f backend
docker-compose logs -f frontend

# Test the application
curl http://localhost:8080        # Frontend
curl http://localhost:5001/health # Backend

# Access in browser: http://localhost:8080
```

**Run tests:**
```bash
# Backend tests
docker-compose exec backend pytest

# Frontend tests
docker-compose exec frontend npm test

# Stop services
docker-compose down
```

### Step 3: Build Production Images

```bash
# Build backend image
cd backend
docker build -t your-registry/backend:v1.0.0 .

# Build frontend image
cd ../frontend
docker build -t your-registry/frontend:v1.0.0 .

# Test images locally
docker run -p 5000:5000 your-registry/backend:v1.0.0
docker run -p 8080:8080 your-registry/frontend:v1.0.0
```

---

## Cloud Infrastructure Setup

### AWS EKS

```bash
cd infrastructure/aws

# Configure AWS credentials
aws configure

# Copy and edit terraform.tfvars
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values

# Initialize Terraform
terraform init

# Plan the deployment
terraform plan -out=tfplan

# Apply the configuration
terraform apply tfplan

# Configure kubectl
aws eks update-kubeconfig --name microservices-dev-eks --region us-east-1

# Verify cluster access
kubectl get nodes
```

---

## Kubernetes Cluster Setup

### Step 1: Create Namespaces

```bash
# Create development namespace
kubectl create namespace dev

# Create production namespace
kubectl create namespace prod

# Label namespaces for network policies
kubectl label namespace dev name=dev
kubectl label namespace prod name=prod
```

### Step 2: Install Essential Add-ons

**Nginx Ingress Controller:**
```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.service.type=LoadBalancer
```

**Cert-Manager for TLS:**
```bash
helm repo add jetstack https://charts.jetstack.io
helm repo update

helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --set installCRDs=true

# Create ClusterIssuer for Let's Encrypt
cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: admin@example.com
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: nginx
EOF
```

**External Secrets Operator (Recommended):**
```bash
helm repo add external-secrets https://charts.external-secrets.io
helm repo update

helm install external-secrets external-secrets/external-secrets \
  --namespace external-secrets \
  --create-namespace
```

### Step 3: Configure Image Pull Secrets

**For GitHub Container Registry:**
```bash
kubectl create secret docker-registry ghcr-secret \
  --docker-server=ghcr.io \
  --docker-username=YOUR_GITHUB_USERNAME \
  --docker-password=YOUR_GITHUB_TOKEN \
  --namespace=dev

kubectl create secret docker-registry ghcr-secret \
  --docker-server=ghcr.io \
  --docker-username=YOUR_GITHUB_USERNAME \
  --docker-password=YOUR_GITHUB_TOKEN \
  --namespace=prod
```

---

## Application Deployment

### Development Environment

**Step 1: Create Database Secrets**
```bash
# Create PostgreSQL credentials
kubectl create secret generic postgresql-secret \
  --from-literal=postgres-password='dev-password-change-me' \
  --namespace=dev

# Create backend database connection secret
kubectl create secret generic backend-secret \
  --from-literal=database-url='postgresql://postgres:dev-password-change-me@postgresql-client.dev.svc.cluster.local:5432/microservices_db' \
  --namespace=dev
```

**Step 2: Deploy PostgreSQL**
```bash
helm install postgresql ./charts/postgresql \
  --namespace dev \
  --values ./charts/postgresql/values-dev.yaml \
  --set postgresql.existingSecret=postgresql-secret \
  --wait

# Verify deployment
kubectl get pods -n dev -l app.kubernetes.io/name=postgresql
kubectl get pvc -n dev
```

**Step 3: Deploy Backend**
```bash
helm install backend ./charts/backend \
  --namespace dev \
  --values ./charts/backend/values-dev.yaml \
  --set image.repository=ghcr.io/YOUR_ORG/backend \
  --set image.tag=v1.0.0 \
  --set imagePullSecrets[0].name=ghcr-secret \
  --wait

# Verify deployment
kubectl get pods -n dev -l app.kubernetes.io/name=backend
kubectl logs -n dev -l app.kubernetes.io/name=backend
```

**Step 4: Deploy Frontend**
```bash
helm install frontend ./charts/frontend \
  --namespace dev \
  --values ./charts/frontend/values-dev.yaml \
  --set image.repository=ghcr.io/YOUR_ORG/frontend \
  --set image.tag=v1.0.0 \
  --set imagePullSecrets[0].name=ghcr-secret \
  --wait

# Verify deployment
kubectl get pods -n dev -l app.kubernetes.io/name=frontend
kubectl get ingress -n dev
```

**Step 5: Verify Deployment**
```bash
# Check all pods are running
kubectl get pods -n dev

# Check services
kubectl get svc -n dev

# Check ingress
kubectl get ingress -n dev

# Get ingress IP/hostname
kubectl get ingress frontend -n dev -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'

# Test the application
curl http://$(kubectl get ingress frontend -n dev -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')/
```

### Production Environment

**IMPORTANT: Production requires manual approval in CI/CD or manual deployment**

**Step 1: Create Production Secrets (SECURE METHOD)**

**Use External Secrets Operator (Recommended):**

For AWS Secrets Manager:
```bash
# Store secrets in AWS Secrets Manager first
aws secretsmanager create-secret \
  --name prod/postgresql/password \
  --secret-string "super-secure-password"

aws secretsmanager create-secret \
  --name prod/backend/database-url \
  --secret-string "postgresql://postgres:super-secure-password@postgresql-client.prod.svc.cluster.local:5432/microservices_db_prod"

# Create ExternalSecret resource
cat <<EOF | kubectl apply -f -
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: postgresql-secret
  namespace: prod
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: aws-secrets-manager
    kind: SecretStore
  target:
    name: postgresql-secret
  data:
  - secretKey: postgres-password
    remoteRef:
      key: prod/postgresql/password
EOF
```

**Step 2: Deploy to Production**
```bash
# Deploy PostgreSQL
helm install postgresql ./charts/postgresql \
  --namespace prod \
  --values ./charts/postgresql/values-prod.yaml \
  --set postgresql.existingSecret=postgresql-secret \
  --wait

# Deploy Backend
helm install backend ./charts/backend \
  --namespace prod \
  --values ./charts/backend/values-prod.yaml \
  --set image.repository=ghcr.io/YOUR_ORG/backend \
  --set image.tag=v1.0.0 \
  --wait

# Deploy Frontend
helm install frontend ./charts/frontend \
  --namespace prod \
  --values ./charts/frontend/values-prod.yaml \
  --set image.repository=ghcr.io/YOUR_ORG/frontend \
  --set image.tag=v1.0.0 \
  --wait
```

### Upgrade Deployments

```bash
# Upgrade with new image version
helm upgrade backend ./charts/backend \
  --namespace dev \
  --reuse-values \
  --set image.tag=v1.1.0 \
  --wait

# Rollback if needed
helm rollback backend -n dev
```

---

## Security Configuration

### Network Policies

Network policies are automatically created when deploying with Helm charts if enabled in values.yaml.

**Verify Network Policies:**
```bash
kubectl get networkpolicies -n dev
kubectl describe networkpolicy frontend -n dev
```

### Pod Security Standards

**Enforce Restricted Pod Security:**
```bash
# Label namespace with pod security standard
kubectl label namespace prod pod-security.kubernetes.io/enforce=restricted
kubectl label namespace prod pod-security.kubernetes.io/audit=restricted
kubectl label namespace prod pod-security.kubernetes.io/warn=restricted
```

### RBAC Configuration

**Create service account with minimal permissions:**
```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: app-deployer
  namespace: dev
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: app-deployer-role
  namespace: dev
rules:
- apiGroups: ["apps"]
  resources: ["deployments"]
  verbs: ["get", "list", "update", "patch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: app-deployer-binding
  namespace: dev
subjects:
- kind: ServiceAccount
  name: app-deployer
  namespace: dev
roleRef:
  kind: Role
  name: app-deployer-role
  apiGroup: rbac.authorization.k8s.io
EOF
```



## Monitoring and Logging

### Install Prometheus & Grafana

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace

# Access Grafana
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80

# Login credentials
# Username: admin
# Password: prom-operator (default)
```

### View Logs

```bash
# Application logs
kubectl logs -n dev -l app.kubernetes.io/name=backend --tail=100 -f
kubectl logs -n dev -l app.kubernetes.io/name=frontend --tail=100 -f

# All pods in namespace
kubectl logs -n dev --all-containers=true --tail=100

# Previous container logs (after crash)
kubectl logs -n dev POD_NAME --previous
```

---

## Troubleshooting

### Common Issues

**1. Docker Compose - Container name conflicts**
```bash
# If encountering "container name already in use" errors:
# List all containers
docker ps -a

# Remove stuck containers
docker rm -f CONTAINER_NAME

# If permission denied, restart Docker daemon
sudo systemctl restart docker

# Then retry
docker compose up -d
```

**2. Frontend build - Missing package-lock.json**
```bash
# Error: npm ci requires package-lock.json
cd frontend
npm install  # Generates package-lock.json
docker compose build frontend
```

**3. Frontend build - TypeScript version mismatch**
```bash
# Error: lock file's typescript@X.X.X does not satisfy typescript@Y.Y.Y
# Solution: Add TypeScript to devDependencies in package.json
# This is already done in the project (typescript: 4.9.5)
cd frontend
npm install
```

**4. Pods not starting - ImagePullBackOff**
```bash
# Check image pull secret
kubectl get secret ghcr-secret -n dev

# Recreate secret
kubectl delete secret ghcr-secret -n dev
kubectl create secret docker-registry ghcr-secret ...

# Restart deployment
kubectl rollout restart deployment/backend -n dev
```

**5. Database connection errors**
```bash
# Check database pod
kubectl get pods -n dev -l app.kubernetes.io/name=postgresql

# Check database logs
kubectl logs -n dev -l app.kubernetes.io/name=postgresql

# Test connection from backend pod
kubectl exec -it -n dev POD_NAME -- psql postgresql://postgres:PASSWORD@postgresql-client:5432/microservices_db
```

**6. Ingress not working**
```bash
# Check ingress controller
kubectl get pods -n ingress-nginx

# Check ingress resource
kubectl describe ingress frontend -n dev

# Check service
kubectl get svc frontend -n dev
```

**7. Network policy blocking traffic**
```bash
# Temporarily disable network policy
kubectl delete networkpolicy frontend -n dev

# Test connection
# If works, fix network policy rules
```

### Health Checks

```bash
# Check pod health
kubectl get pods -n dev

# Describe pod for events
kubectl describe pod POD_NAME -n dev

# Check readiness/liveness probes
kubectl get pod POD_NAME -n dev -o jsonpath='{.status.conditions}'
```

### Debugging

```bash
# Execute shell in pod
kubectl exec -it -n dev POD_NAME -- /bin/sh

# Port forward for local testing
kubectl port-forward -n dev svc/backend 5001:5000
curl http://localhost:5001/health

# View all events
kubectl get events -n dev --sort-by='.lastTimestamp'
```

---

## Cleanup

### Remove Application

```bash
# Delete Helm releases
helm uninstall frontend -n dev
helm uninstall backend -n dev
helm uninstall postgresql -n dev

# Delete namespace (removes all resources)
kubectl delete namespace dev
```

### Destroy Infrastructure

```bash
cd infrastructure/aws  # or azure/gcp

# WARNING: This deletes everything!
terraform destroy

# Confirm with 'yes'
```

---

