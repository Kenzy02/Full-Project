# Helm Charts

This directory contains Helm charts for deploying the Task Manager application to Kubernetes. Detailed architecture and communication diagrams can be found in the [Documentation](./documentation.md).

## Charts

- **backend** - Flask API service
- **frontend** - React/Nginx web service  
- **postgresql** - PostgreSQL database service

## Structure

Each chart follows the standard Helm chart structure:

```
charts/
├── backend/
│   ├── Chart.yaml                # Chart metadata
│   ├── values.yaml              # Default values
│   ├── values-dev.yaml          # Development overrides
│   ├── values-prod.yaml         # Production overrides
│   └── templates/               # Kubernetes manifests
│       ├── namespace.yaml
│       ├── configmap.yaml
│       ├── secret.yaml
│       ├── deployment.yaml
│       ├── service.yaml
│       ├── hpa.yaml
│       └── pdb.yaml
├── frontend/                    # Same structure
└── postgresql/                  # Same structure + PV/PVC
```

## Installation

### Prerequisites

- Kubernetes cluster (v1.28+)
- Helm 3.13+
- kubectl configured

### Deploy All Services

Deploy in order:

```bash
# 1. PostgreSQL (database)
helm install postgresql ./charts/postgresql

# 2. Backend (API)
helm install backend ./charts/backend

# 3. Frontend (Web UI)
helm install frontend ./charts/frontend
```

### Deploy with Environment-Specific Values

**Development:**
```bash
helm install postgresql ./charts/postgresql --values ./charts/postgresql/values-dev.yaml
helm install backend ./charts/backend --values ./charts/backend/values-dev.yaml
helm install frontend ./charts/frontend --values ./charts/frontend/values-dev.yaml
```

**Production:**
```bash
helm install postgresql ./charts/postgresql --values ./charts/postgresql/values-prod.yaml
helm install backend ./charts/backend --values ./charts/backend/values-prod.yaml
helm install frontend ./charts/frontend --values ./charts/frontend/values-prod.yaml
```

### Deploy to Custom Namespace

```bash
helm install postgresql ./charts/postgresql --namespace my-namespace --create-namespace
```

## Upgrade

```bash
helm upgrade postgresql ./charts/postgresql
helm upgrade backend ./charts/backend
helm upgrade frontend ./charts/frontend
```

## Uninstall

```bash
helm uninstall frontend
helm uninstall backend
helm uninstall postgresql
```

## Configuration

### Backend Values

| Parameter | Description | Default |
|-----------|-------------|---------|
| `namespace` | Kubernetes namespace | `pro-be` |
| `image.repository` | Docker image repository | `kenzyehab/project-backend` |
| `image.tag` | Image tag | `5d34b45` |
| `replicas` | Number of replicas | `2` |
| `resources.requests.cpu` | CPU request | `100m` |
| `resources.requests.memory` | Memory request | `128Mi` |
| `config.DATABASE_HOST` | Database host | `postgresql-service.pro-db.svc.cluster.local` |
| `config.FLASK_ENV` | Flask environment | `production` |
| `hpa.minReplicas` | Min HPA replicas | `2` |
| `hpa.maxReplicas` | Max HPA replicas | `5` |

### Frontend Values

| Parameter | Description | Default |
|-----------|-------------|---------|
| `namespace` | Kubernetes namespace | `pro-fe` |
| `image.repository` | Docker image repository | `kenzyehab/project-frontend` |
| `image.tag` | Image tag | `5d34b45` |
| `replicas` | Number of replicas | `2` |
| `resources.requests.cpu` | CPU request | `50m` |
| `resources.requests.memory` | Memory request | `64Mi` |
| `service.port` | Service port | `80` |
| `service.targetPort` | Container port | `8080` |

### PostgreSQL Values

| Parameter | Description | Default |
|-----------|-------------|---------|
| `namespace` | Kubernetes namespace | `pro-db` |
| `image.repository` | Docker image repository | `postgres` |
| `image.tag` | Image tag | `15-alpine` |
| `storage.capacity` | PVC storage size | `10Gi` |
| `secrets.postgres_user` | PostgreSQL username | `postgres` |
| `secrets.postgres_password` | PostgreSQL password | `postgres` |
| `secrets.postgres_db` | Database name | `taskmanager` |

## Customization

### Override Values

Create a custom `my-values.yaml`:

```yaml
replicas: 3
image:
  tag: "latest"
resources:
  limits:
    cpu: 1000m
    memory: 1Gi
```

Apply it:
```bash
helm install backend ./charts/backend --values my-values.yaml
```

### Template a Chart

View rendered manifests without installing:

```bash
helm template backend ./charts/backend
```

### Debug

```bash
helm install backend ./charts/backend --dry-run --debug
```

## Features

- **Autoscaling**: HPA configured for all services
- **High Availability**: PDB ensures minimum replicas during disruptions
- **Security**: Non-root containers, resource limits, capabilities dropped
- **Health Checks**: Liveness and readiness probes
- **Persistence**: PersistentVolume for database
- **Secrets Management**: Database credentials in Kubernetes secrets
- **ConfigMaps**: Application configuration externalized

## Chart Versions

| Chart | Version | App Version |
|-------|---------|-------------|
| backend | 1.0.0 | 1.0.0 |
| frontend | 1.0.0 | 1.0.0 |
| postgresql | 1.0.0 | 15 |

## Validation

Lint charts:
```bash
helm lint ./charts/backend
helm lint ./charts/frontend
helm lint ./charts/postgresql
```

## Notes

- Namespaces are created by charts
- Charts are based on the k8s/ directory manifests
- Production values include higher resource limits and replica counts
- Database initialization SQL is in ConfigMap
