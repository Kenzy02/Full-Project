# Task Manager - Kubernetes Manifests

Complete Kubernetes deployment configuration for the Task Manager application, migrated from Helm charts to pure Kubernetes YAML manifests.

## 📁 Directory Structure

```
k8s/
├── database/              # PostgreSQL Database Resources
│   ├── 00-namespace.yaml
│   ├── 01-persistentvolume.yaml
│   ├── 02-persistentvolumeclaim.yaml
│   ├── 03-secret.yaml
│   ├── 04-configmap-schema.yaml
│   ├── 05-deployment.yaml
│   └── 06-service.yaml
├── backend/               # Python/Flask Backend API Resources
│   ├── 00-namespace.yaml
│   ├── 01-configmap.yaml
│   ├── 02-deployment.yaml
│   ├── 03-secret.yaml
│   └── 04-service.yaml
├── frontend/              # React/Nginx Frontend Resources
│   ├── 00-namespace.yaml
│   ├── 01-configmap-nginx.yaml
│   ├── 02-deployment.yaml
│   └── 03-service.yaml
├── ingress.yaml           # Ingress for external access
├── Makefile               # Automation for deploy/scan/cleanup
├── .sonarcloud.properties # SAST configuration
└── README.md              # This file
```

## 🎯 Components

### Database (PostgreSQL)
- **Namespace**: `pro-db`
- **Features**:
  - PersistentVolume (10Gi) for data storage
  - Secret for credentials (user: postgres, password: postgres)
  - ConfigMap with `schema.sql` for automatic database initialization
  - Solves "relation 'task' does not exist" error
  - Health checks (liveness & readiness probes)
  - Resource limits: 250m CPU / 256Mi RAM (request), 500m CPU / 512Mi RAM (limit)

### Backend (Flask API)
- **Namespace**: `pro-be`
- **Features**:
  - InitContainer to wait for database readiness
  - Environment variables from ConfigMap and Secret
  - Security context with non-root user (UID 1000)
  - Resource limits: 100m CPU / 128Mi RAM (request), 500m CPU / 512Mi RAM (limit)
  - Health endpoints: `/health` and `/ready`
  - 2 replicas with RollingUpdate strategy

### Frontend (React/Nginx)
- **Namespace**: `pro-fe`
- **Features**:
  - Custom Nginx config running on port 8080 (non-privileged)
  - Solves "/var/run/nginx.pid permission denied" error
  - Proxy configuration for `/api` requests to backend
  - Security context with non-root user (UID 101 - nginx)
  - EmptyDir volumes for tmp, cache, and run directories
  - Resource limits: 50m CPU / 64Mi RAM (request), 200m CPU / 256Mi RAM (limit)
  - 2 replicas with RollingUpdate strategy

### Networking
- **Ingress**: Exposes frontend on `localhost`
- **Service Type**: All services use ClusterIP (internal)
- **Cross-namespace communication**: Services configured with FQDN

## 🚀 Quick Start

### Prerequisites
- Kubernetes cluster (minikube, kind, or cloud provider)
- kubectl configured
- Trivy installed (for security scanning)
- Nginx Ingress Controller (for Ingress)

### Enable Ingress on Minikube
```bash
minikube addons enable ingress
```

### Deploy All Components
```bash
cd k8s/
make deploy
```

### Scan Images Before Deployment
```bash
make scan-deploy
```

## 📋 Makefile Commands

```bash
make help              # Show all available commands
make scan-images       # Scan all Docker images with Trivy
make scan-backend      # Scan backend image only
make scan-frontend     # Scan frontend image only
make scan-database     # Scan database image only

make deploy            # Deploy all components
make deploy-database   # Deploy database only
make deploy-backend    # Deploy backend only
make deploy-frontend   # Deploy frontend only
make deploy-ingress    # Deploy ingress only

make status            # Show status of all components
make logs-database     # Show database logs
make logs-backend      # Show backend logs
make logs-frontend     # Show frontend logs

make restart-database  # Restart database pods
make restart-backend   # Restart backend pods
make restart-frontend  # Restart frontend pods

make delete            # Delete all resources
make delete-database   # Delete database resources
make delete-backend    # Delete backend resources
make delete-frontend   # Delete frontend resources

make clean             # Clean up all resources
```

## 🔧 Manual Deployment

If you prefer to deploy components manually:

### 1. Deploy Database
```bash
kubectl apply -f database/
```

Wait for database to be ready:
```bash
kubectl wait --for=condition=ready pod -l app=postgresql -n pro-db --timeout=120s
```

### 2. Deploy Backend
```bash
kubectl apply -f backend/
```

### 3. Deploy Frontend
```bash
kubectl apply -f frontend/
```

### 4. Deploy Ingress
```bash
kubectl apply -f ingress.yaml
```

## 🔍 Verification

### Check Pod Status
```bash
kubectl get pods -n pro-db
kubectl get pods -n pro-be
kubectl get pods -n pro-fe
```

### Check Services
```bash
kubectl get svc -n pro-db
kubectl get svc -n pro-be
kubectl get svc -n pro-fe
```

### Check Ingress
```bash
kubectl get ingress -n pro-fe
```

### View Logs
```bash
kubectl logs -f deployment/postgresql -n pro-db
kubectl logs -f deployment/backend -n pro-be
kubectl logs -f deployment/frontend -n pro-fe
```

## 🌐 Access Application

Once deployed, access the application:
- **URL**: http://localhost
- **API**: http://localhost/api

For Minikube, you may need to run:
```bash
minikube tunnel
```

Or get the Ingress address:
```bash
kubectl get ingress -n pro-fe
```

## 🔒 Security Features

### Database
- ✅ Non-root user (UID 999)
- ✅ Credentials stored in Secret
- ✅ PersistentVolume for data persistence
- ✅ Resource limits defined

### Backend
- ✅ Non-root user (UID 1000)
- ✅ InitContainer for dependency management
- ✅ Read-only root filesystem capability
- ✅ All Linux capabilities dropped
- ✅ Secrets for database credentials
- ✅ No privilege escalation

### Frontend
- ✅ Non-root user (UID 101)
- ✅ Nginx on port 8080 (non-privileged)
- ✅ EmptyDir volumes for writable directories
- ✅ All Linux capabilities dropped
- ✅ No privilege escalation

## 🛡️ Security Scanning

### Trivy Image Scanning
Scan all images before deployment:
```bash
make scan-images
```

Individual scans:
```bash
trivy image kenzyehab/project-backend:latest
trivy image kenzyehab/project-frontend:latest
trivy image postgres:15-alpine
```

### SonarCloud SAST
Configure `.sonarcloud.properties` with your project details:
1. Update `sonar.organization` with your SonarCloud organization
2. Update `sonar.projectKey` with your project key
3. Run SonarCloud scanner

## 🐛 Troubleshooting

### Database Issues

**Problem**: Relation "task" does not exist
- **Solution**: The schema.sql in ConfigMap creates the required tables automatically on initialization

**Problem**: Database pod not starting
```bash
kubectl describe pod -l app=postgresql -n pro-db
kubectl logs -l app=postgresql -n pro-db
```

### Backend Issues

**Problem**: Backend can't connect to database
- Check InitContainer logs: `kubectl logs <pod-name> -c wait-for-db -n pro-be`
- Verify database service: `kubectl get svc -n pro-db`
- Check database credentials in Secret

**Problem**: Backend pod crashloop
```bash
kubectl logs -l app=backend -n pro-be --previous
```

### Frontend Issues

**Problem**: Nginx permission denied on /var/run/nginx.pid
- **Solution**: Already fixed - nginx.conf uses `/tmp/nginx.pid` and runs on port 8080

**Problem**: Frontend can't reach backend
- Verify backend service: `kubectl get svc -n pro-be`
- Check Ingress configuration: `kubectl describe ingress -n pro-fe`

### Ingress Issues

**Problem**: Ingress not working
```bash
# Check Ingress controller
kubectl get pods -n ingress-nginx

# For Minikube
minikube addons enable ingress

# Check Ingress events
kubectl describe ingress taskmanager-ingress -n pro-fe
```

## 🔄 Updates and Rollbacks

### Update Image Version
Edit the deployment files and change the image tag:
```bash
# Edit backend deployment
kubectl edit deployment backend -n pro-be

# Or update and apply
kubectl apply -f backend/02-deployment.yaml
```

### Rollback Deployment
```bash
# Rollback backend
kubectl rollout undo deployment/backend -n pro-be

# View rollout history
kubectl rollout history deployment/backend -n pro-be
```

## 📊 Monitoring

### Resource Usage
```bash
kubectl top pods -n pro-db
kubectl top pods -n pro-be
kubectl top pods -n pro-fe
```

### Events
```bash
kubectl get events -n pro-db --sort-by='.lastTimestamp'
kubectl get events -n pro-be --sort-by='.lastTimestamp'
kubectl get events -n pro-fe --sort-by='.lastTimestamp'
```

## 🧹 Cleanup

Remove all resources:
```bash
make delete
```

Or manually:
```bash
kubectl delete -f ingress.yaml
kubectl delete -f frontend/
kubectl delete -f backend/
kubectl delete -f database/
```

## 📝 Notes

1. **Secrets**: The provided secrets use base64 encoding of 'postgres'. In production, use proper secret management (Sealed Secrets, External Secrets Operator, or cloud provider secrets).

2. **Storage**: The PersistentVolume uses `hostPath` which is suitable for development. For production, use cloud provider storage classes.

3. **Database Initialization**: The schema.sql in ConfigMap runs only on first initialization. If you need to re-initialize, delete the PVC and redeploy.

4. **Resource Limits**: Adjust CPU and memory limits based on your workload requirements.

5. **Ingress**: Make sure you have an Ingress controller installed in your cluster.

## 🤝 Migration from Helm

This configuration replaces the Helm charts with pure Kubernetes manifests:
- ✅ Removed Helm templating complexity
- ✅ Direct YAML files easier to understand and modify
- ✅ All security features maintained
- ✅ Added comprehensive documentation
- ✅ Simplified deployment process

## 📚 Additional Resources

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Trivy Security Scanner](https://aquasecurity.github.io/trivy/)
- [SonarCloud](https://sonarcloud.io/)
- [Nginx Ingress Controller](https://kubernetes.github.io/ingress-nginx/)
