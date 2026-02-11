# Quick Start Guide

Deploy and run the Task Manager application with a single command!

## 🚀 Quick Deploy

### One-Command Installation

```bash
# Deploy with development settings (default)
./deploy-helm.sh

# Or deploy with production settings
./deploy-helm.sh prod
```

This script will:
1. ✅ Check prerequisites (kubectl, helm, kubernetes)
2. ✅ Clean up old deployments
3. ✅ Deploy PostgreSQL database
4. ✅ Deploy Backend API service
5. ✅ Deploy Frontend web application
6. ✅ Wait for all pods to be ready
7. ✅ Set up port forwarding
8. ✅ Automatically open the app in your browser

### What You See

The script provides colored output with progress:

```
╔════════════════════════════════════════════════════════════╗
║  Task Manager - Helm Deployment & Browser Launcher        ║
╚════════════════════════════════════════════════════════════╝

Environment: dev

Checking Kubernetes connection...
✓ Connected to Kubernetes

Cleaning up old deployments (if any)...
✓ Cleanup complete

Deploying PostgreSQL...
✓ PostgreSQL deployed

Waiting for PostgreSQL to be ready...
✓ PostgreSQL is running

Deploying Backend...
✓ Backend deployed

Waiting for Backend to be ready...
✓ Backend is running

Deploying Frontend...
✓ Frontend deployed

Waiting for Frontend to be ready...
✓ Frontend is running

Setting up port forwarding...
✓ Port forwarding started (PID: 12345)

╔════════════════════════════════════════════════════════════╗
✓ All services deployed successfully!
╚════════════════════════════════════════════════════════════╝

Connection Information:
  Frontend:  http://localhost:8080
  Backend:   http://localhost:5000/api/tasks
  Swagger:   http://localhost:5000/api/docs

Pod Status:
NAME                          READY   STATUS    RESTARTS   AGE
postgresql-6c7bbd94c7-drmsw   1/1     Running   0          28s
backend-65f56444c-2klhd       1/1     Running   0          20s
frontend-5bc87899dd-7lw9w     1/1     Running   0          12s

Helm Releases:
frontend        pro-fe     1  deployed  frontend-1.0.0     1.0.0
backend         pro-be     1  deployed  backend-1.0.0      1.0.0
postgresql      pro-db     1  deployed  postgresql-1.0.0   15

Opening browser...
```

## 📋 Available Scripts

### `deploy-helm.sh`
Deploy the entire application stack with Helm charts and open in browser.

**Usage:**
```bash
./deploy-helm.sh        # Deploy with dev settings
./deploy-helm.sh prod   # Deploy with prod settings
```

**Features:**
- Checks all prerequisites (kubectl, helm, k8s cluster)
- Cleans up old deployments
- Deploys PostgreSQL, Backend, and Frontend
- Waits for each service to be ready
- Automatically sets up port forwarding
- Opens browser automatically (Linux/macOS)
- Shows deployment status and connection info

### `uninstall-helm.sh`
Uninstall all Helm releases and clean up resources.

**Usage:**
```bash
./uninstall-helm.sh
```

**Features:**
- Stops port forwarding
- Uninstalls all Helm releases
- Deletes all namespaces
- Confirms before deletion

## 🎯 Usage

### Prerequisites

- Linux/macOS with bash
- `kubectl` installed and configured
- `helm` 3.13+ installed
- Kubernetes cluster running (minikube, Docker Desktop, EKS, etc.)

### Deployment

```bash
# Deploy application and open in browser
./deploy-helm.sh

# Or with production settings
./deploy-helm.sh prod
```

### Access the Application

After deployment:
- **Frontend UI**: http://localhost:8080
- **Swagger API Docs**: http://localhost:8080/api/docs

### Port Forwarding (Manual)

If you need to manually access services:

```bash
# Frontend (already forwarded)
kubectl port-forward svc/frontend-service 8080:80 -n pro-fe

# Backend API (if needed)
kubectl port-forward svc/backend-service 5000:5000 -n pro-be

# PostgreSQL Database (if needed)
kubectl port-forward svc/postgresql-service 5432:5432 -n pro-db
```

### Check Status

```bash
# View all resources
kubectl get all -n pro-db
kubectl get all -n pro-be
kubectl get all -n pro-fe

# Check pod status
kubectl get pods -A | grep pro-

# View logs
kubectl logs -f deployment/frontend -n pro-fe
kubectl logs -f deployment/backend -n pro-be
kubectl logs -f deployment/postgresql -n pro-db
```

### Stop the Application

**Keep port forwarding running (for browser access):**
```bash
pkill -f "kubectl port-forward"
```

**or let the script do it on exit**

## 🗑️ Uninstall

Remove the entire application:

```bash
./uninstall-helm.sh
```

This will:
1. Stop port forwarding
2. Uninstall all Helm releases
3. Delete all namespaces
4. Remove all resources

## 📊 Deployment Details

### Namespaces

| Namespace | Purpose | Resources |
|-----------|---------|-----------|
| `pro-db` | Database | PostgreSQL deployment, PVC, Service |
| `pro-be` | Backend API | Flask deployment, Service, ConfigMap |
| `pro-fe` | Frontend UI | Nginx deployment, Service, ConfigMap |

### Helm Releases

```bash
helm list -A | grep pro-

# Output:
# backend         pro-be     1  deployed  backend-1.0.0      1.0.0
# frontend        pro-fe     1  deployed  frontend-1.0.0     1.0.0
# postgresql      pro-db     1  deployed  postgresql-1.0.0   15
```

### Port Forwarding

The deploy script automatically forwards:
- `localhost:8080` → `frontend-service:80` (in pro-fe namespace)

### Browser Auto-Open

The script attempts to open your browser using:
- macOS: `open`
- Linux: `xdg-open`
- Windows: `explorer.exe` or Firefox
- WSL: `wsl-open`

If auto-open doesn't work, manually visit: http://localhost:8080

## 🐛 Troubleshooting

### Issue: "kubectl is not installed"

```bash
# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
```

### Issue: "Helm is not installed"

```bash
# Install Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

### Issue: "Kubernetes cluster is not accessible"

```bash
# Check cluster connection
kubectl cluster-info

# If minikube, start it
minikube start

# Check kubeconfig
cat $HOME/.kube/config
```

### Issue: Port 8080 already in use

```bash
# Find process using port 8080
lsof -i :8080

# Or change port in deploy.sh (edit LOCAL_PORT variable)
```

### Issue: Pods not starting

```bash
# Check pod events
kubectl describe pod <pod-name> -n <namespace>

# View logs
kubectl logs <pod-name> -n <namespace>

# Check resource availability
kubectl top nodes
kubectl top pods -A
```

### Issue: Browser doesn't auto-open

```bash
# Manually open
open http://localhost:8080    # macOS
xdg-open http://localhost:8080 # Linux
# or copy-paste into your browser: http://localhost:8080
```

## 📚 Additional Commands

### View Chart Values

```bash
helm get values postgresql -n pro-db
helm get values backend -n pro-be
helm get values frontend -n pro-fe
```

### Edit Deployment

```bash
# Upgrade with custom values
helm upgrade frontend ./charts/frontend \
  --values ./charts/frontend/values-dev.yaml \
  -n pro-fe

# Rollback to previous version
helm rollback frontend -n pro-fe
```

### Delete Specific Release

```bash
helm uninstall frontend -n pro-fe
helm uninstall backend -n pro-be
helm uninstall postgresql -n pro-db
```

## 🔗 Related Documentation

- [Charts README](./charts/README.md) - Helm chart details
- [Kubernetes Manifests](./k8s/) - Raw K8s YAML files
- [CI/CD Pipeline](./github/workflows/ci-cd.yaml) - GitHub Actions workflow

## ✨ Features

- ✓ One-click deployment
- ✓ Automatic browser launch
- ✓ Port forwarding setup
- ✓ Health checks and verification
- ✓ Colored terminal output
- ✓ Graceful error handling
- ✓ Easy uninstall
- ✓ Works on Linux, macOS, Windows (WSL)


