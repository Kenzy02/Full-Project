# Quick Reference - Task Manager Kubernetes

## 🚀 Quick Deploy

### Option 1: Using Makefile (Recommended)
```bash
cd k8s/
make deploy
```

### Option 2: Using Deploy Script
```bash
cd k8s/
./deploy.sh
```

### Option 3: Manual
```bash
cd k8s/
kubectl apply -f database/
kubectl apply -f backend/
kubectl apply -f frontend/
kubectl apply -f ingress.yaml
```

## 🔍 Quick Check

```bash
# Check all pods
kubectl get pods --all-namespaces | grep -E 'pro-db|pro-be|pro-fe'

# Check services
kubectl get svc -n pro-db -n pro-be -n pro-fe

# Check ingress
kubectl get ingress -n pro-fe
```

## 📊 Status

```bash
make status
```

## 📝 Logs

```bash
# Database
make logs-database
# or
kubectl logs -f -l app=postgresql -n pro-db

# Backend
make logs-backend
# or
kubectl logs -f -l app=backend -n pro-be

# Frontend
make logs-frontend
# or
kubectl logs -f -l app=frontend -n pro-fe
```

## 🔄 Restart Components

```bash
make restart-database
make restart-backend
make restart-frontend
```

## 🛡️ Security Scan

```bash
# Scan all images
make scan-images

# Scan and deploy
make scan-deploy
```

## 🧹 Cleanup

```bash
make delete
```

## 🌐 Access

- **Frontend**: http://localhost
- **Backend API**: http://localhost/api

### For Minikube
```bash
minikube tunnel
```

## 🐛 Troubleshooting

### Database not starting
```bash
kubectl describe pod -l app=postgresql -n pro-db
kubectl logs -l app=postgresql -n pro-db
```

### Backend can't connect to DB
```bash
# Check database service
kubectl get svc postgresql-service -n pro-db

# Check backend InitContainer
kubectl logs <backend-pod> -c wait-for-db -n pro-be

# Check backend main container
kubectl logs <backend-pod> -c backend -n pro-be
```

### Frontend Nginx errors
```bash
kubectl logs -l app=frontend -n pro-fe
kubectl describe pod -l app=frontend -n pro-fe
```

### Ingress not working
```bash
# Enable ingress on Minikube
minikube addons enable ingress

# Check ingress controller
kubectl get pods -n ingress-nginx

# Check ingress details
kubectl describe ingress taskmanager-ingress -n pro-fe
```

## 📦 Component Details

### Namespaces
- `pro-db` - PostgreSQL database
- `pro-be` - Backend API
- `pro-fe` - Frontend web

### Secrets (Base64 Encoded)
- Database: `postgres` / `postgres`
- Backend: `postgres` / `postgres`

### Resource Limits
| Component | CPU Request | Memory Request | CPU Limit | Memory Limit |
|-----------|-------------|----------------|-----------|--------------|
| Database  | 250m        | 256Mi          | 500m      | 512Mi        |
| Backend   | 100m        | 128Mi          | 500m      | 512Mi        |
| Frontend  | 50m         | 64Mi           | 200m      | 256Mi        |

### Ports
- Database: 5432
- Backend: 5000
- Frontend: 8080 (internal), 80 (service)

## ⚙️ Configuration Files

- **Database Schema**: `database/04-configmap-schema.yaml`
- **Backend Config**: `backend/01-configmap.yaml`
- **Nginx Config**: `frontend/01-configmap-nginx.yaml`
- **Ingress**: `ingress.yaml`

## 🔐 Security Features

✅ All containers run as non-root users  
✅ Resource limits defined  
✅ Security contexts configured  
✅ Capabilities dropped  
✅ ReadOnlyRootFilesystem where possible  
✅ No privilege escalation  
✅ Secrets for sensitive data  
✅ Health probes configured  

## 📚 Files Summary

```
k8s/
├── database/          # 7 files (namespace, PV, PVC, secret, configmap, deployment, service)
├── backend/           # 5 files (namespace, configmap, deployment, secret, service)
├── frontend/          # 4 files (namespace, configmap, deployment, service)
├── ingress.yaml       # Ingress configuration
├── Makefile           # Automation commands
├── deploy.sh          # Quick deployment script
├── README.md          # Full documentation
├── QUICKSTART.md      # This file
└── .sonarcloud.properties  # SAST configuration
```

## 💡 Tips

1. Always check pod status after deployment
2. Use `make status` for quick overview
3. Check logs if pods are not ready
4. For Minikube, ensure ingress addon is enabled
5. Use `kubectl describe` for detailed debugging
6. Run Trivy scans before production deployment
