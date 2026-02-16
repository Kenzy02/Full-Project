# Production-Ready Kubernetes Deployment - Full-Stack Microservices

[![CI/CD Pipeline](https://github.com/YOUR_ORG/project/actions/workflows/ci-cd.yaml/badge.svg)](https://github.com/YOUR_ORG/project/actions)
[![Security Scan](https://img.shields.io/badge/security-trivy-blue)](https://github.com/aquasecurity/trivy)
[![Code Quality](https://sonarcloud.io/api/project_badges/measure?project=YOUR_PROJECT&metric=alert_status)](https://sonarcloud.io/dashboard?id=YOUR_PROJECT)

## 🎯 Project Overview

A **production-ready, full-stack microservices application** with complete Kubernetes deployment automation, security hardening, and GitOps CI/CD pipeline. This project demonstrates enterprise-grade DevSecOps practices with **shift-left security**, **infrastructure as code**, and **cloud-agnostic** Kubernetes deployments.

### Key Features

✅ **Production-ready Helm Charts** - Mono-repo with separate charts for frontend, backend, and database  
✅ **Security Hardened** - Non-root containers, read-only filesystems, network policies  
✅ **Multi-Cloud Ready** - Terraform modules for AWS (EKS), Azure (AKS), and GCP (GKE)  
✅ **Automated CI/CD** - GitHub Actions with SAST, container scanning, and automated deployments  
✅ **GitOps Compliant** - Declarative configurations, version controlled  
✅ **Comprehensive Documentation** - Step-by-step deployment guides and security explanations

---

## 📋 Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Ingress Controller                    │
│              (Nginx / AWS ALB / Azure AG)               │
└──────────────┬──────────────────────┬───────────────────┘
               │                      │
       ┌───────▼──────┐      ┌────────▼────────┐
       │   Frontend   │      │    Backend      │
       │   (React)    │◄─────┤   (Flask API)   │
       │  Nginx:8080  │      │  Gunicorn:5000  │
       └──────────────┘      └────────┬────────┘
                                      │
                             ┌────────▼─────────┐
                             │   PostgreSQL     │
                             │  StatefulSet     │
                             │   (Persistent)   │
                             └──────────────────┘
```

### Technology Stack

**Application:**
- **Frontend:** React 18 + Material-UI, served by Nginx
- **Backend:** Python 3.11 + Flask + SQLAlchemy + Gunicorn
- **Database:** PostgreSQL 15 with automated backups

**Infrastructure:**
- **Container Orchestration:** Kubernetes 1.28+
- **Package Manager:** Helm 3
- **Cloud Providers:** AWS EKS / Azure AKS / GCP GKE
- **Infrastructure as Code:** Terraform
- **Container Registry:** GitHub Container Registry (GHCR)

**Security & Quality:**
- **SAST:** SonarCloud
- **Container Scanning:** Trivy
- **Secret Management:** External Secrets Operator
- **Network Security:** Calico Network Policies
- **Image Hardening:** Multi-stage builds, non-root users

---

## 🚀 Quick Start

### Prerequisites

```bash
# Install required tools
helm version        # v3.13+
kubectl version     # v1.28+
docker --version    # 24.0+
terraform version   # 1.5+
```

### Local Development (Docker Compose)

```bash
# Clone repository
git clone https://github.com/YOUR_ORG/project.git
cd project

# Frontend setup (first time only)
cd frontend
npm install  # Generates package-lock.json
cd ..

# Start all services
docker-compose up -d

# Access application
# Frontend: http://localhost:8080
# Backend:  http://localhost:5001
# API Docs: http://localhost:5001/api/docs

# Run tests
docker-compose exec backend pytest
docker-compose exec frontend npm test

# Stop services
docker-compose down
```

### Production Deployment

See the comprehensive **[DEPLOYMENT.md](DEPLOYMENT.md)** guide for:
- Cloud infrastructure setup (AWS/Azure/GCP)
- Kubernetes cluster configuration
- Helm chart deployment
- CI/CD pipeline integration
- Security hardening
- Monitoring and logging

---

## 📁 Project Structure

```
project/
├── .github/
│   └── workflows/
│       └── ci-cd.yaml              # Complete CI/CD pipeline
├── backend/
│   ├── app.py                       # Flask application
│   ├── requirements.txt             # Python dependencies
│   └── Dockerfile                   # Hardened multi-stage build
├── frontend/
│   ├── src/                         # React source code
│   ├── public/                      # Static assets
│   │   ├── index.html               # HTML template
│   │   ├── manifest.json            # PWA manifest
│   │   └── robots.txt               # SEO robots file
│   ├── package.json                 # Node dependencies
│   ├── package-lock.json            # Locked versions (npm ci)
│   ├── nginx.conf                   # Nginx configuration
│   └── Dockerfile                   # Hardened multi-stage build
├── charts/                          # Helm charts mono-repo
│   ├── frontend/
│   │   ├── Chart.yaml
│   │   ├── values.yaml              # Default values
│   │   ├── values-dev.yaml          # Development overrides
│   │   ├── values-prod.yaml         # Production overrides
│   │   └── templates/               # K8s manifests
│   │       ├── deployment.yaml
│   │       ├── service.yaml
│   │       ├── ingress.yaml
│   │       ├── networkpolicy.yaml
│   │       └── ...
│   ├── backend/
│   │   ├── Chart.yaml
│   │   ├── values.yaml
│   │   ├── values-dev.yaml
│   │   ├── values-prod.yaml
│   │   └── templates/
│   │       ├── deployment.yaml
│   │       ├── service.yaml
│   │       ├── hpa.yaml             # Horizontal Pod Autoscaler
│   │       ├── secret.yaml
│   │       └── ...
│   └── postgresql/
│       ├── Chart.yaml
│       ├── values.yaml
│       ├── values-dev.yaml
│       ├── values-prod.yaml
│       └── templates/
│           ├── statefulset.yaml
│           ├── service.yaml
│           ├── pvc.yaml
│           ├── backup-cronjob.yaml
│           └── ...
├── infrastructure/                  # Terraform IaC
│   ├── aws/
│   │   ├── main.tf                  # EKS cluster
│   │   ├── variables.tf
│   │   └── outputs.tf
│ 
├── docker-compose.yml               # Local development
├── sonar-project.properties         # SonarCloud config
├── .trivy.yaml                      # Trivy scanner config
├── DEPLOYMENT.md                    # Detailed deployment guide
├── DOCKER_SECURITY.md               # Security documentation
└── README.md                        # This file
```

---

## 🔒 Security Features

### Shift-Left Security

**Code Level:**
- SonarCloud SAST scanning for code quality and vulnerabilities
- Dependency scanning with npm audit and pip audit
- Unit test coverage requirements

**Container Level:**
- Multi-stage Docker builds (reduced attack surface)
- Non-root user execution (UID 1000/101)
- Read-only root filesystem
- No hardcoded secrets
- Trivy vulnerability scanning (fails on CRITICAL/HIGH)

**Kubernetes Level:**
- Network Policies (zero-trust networking)
- Pod Security Standards (restricted)
- RBAC with minimal permissions
- Secrets via External Secrets Operator
- Pod Disruption Budgets for availability
- Resource limits and requests

**Infrastructure Level:**
- Private Kubernetes endpoints (production)
- Encrypted data at rest (KMS/Azure Key Vault)
- VPC/VNet isolation
- Security groups / Network Security Groups

---

## 🔄 CI/CD Pipeline

The GitHub Actions pipeline includes:

**Pipeline Stages:**
1. **Build** - Multi-arch Docker images with BuildKit
2. **SAST** - SonarCloud code analysis
3. **Container Scan** - Trivy vulnerability detection
4. **Helm Lint** - Kubernetes manifest validation
5. **Unit Tests** - Backend (pytest) + Frontend (jest)
6. **Deploy Dev** - Automatic deployment to development
7. **Deploy Prod** - Manual approval required

**Security Gates:**
- ❌ Build fails on CRITICAL/HIGH vulnerabilities
- ❌ Build fails on SonarCloud quality gate
- ❌ Build fails on Helm validation errors
- ✅ Manual approval required for production

---

## 📊 Monitoring & Observability

### Included Configurations

**Prometheus Metrics:**
- Application metrics (custom endpoints)
- Kubernetes metrics (kube-state-metrics)
- Node metrics (node-exporter)
- PostgreSQL metrics (postgres-exporter)

**Grafana Dashboards:**
- Kubernetes cluster overview
- Application performance
- Database monitoring
- Resource utilization

**Logging:**
- Structured JSON logging
- Centralized log aggregation
- Log retention policies

---

## 🌐 Multi-Cloud Support

### AWS (Amazon EKS)
```bash
cd infrastructure/aws
terraform init
terraform apply
aws eks update-kubeconfig --name my-cluster
```

**Features:**
- VPC with public/private subnets
- EKS cluster with managed node groups
- EBS CSI driver for persistent volumes
- AWS Load Balancer Controller
- KMS encryption for secrets

### Azure (AKS)
```bash
cd infrastructure/azure
terraform init
terraform apply
az aks get-credentials --resource-group my-rg --name my-cluster
```

**Features:**
- Virtual Network with subnet isolation
- AKS with Azure CNI
- Azure Disk CSI driver
- Azure Load Balancer
- Azure Key Vault integration

### GCP (GKE)
```bash
cd infrastructure/gcp
terraform init
terraform apply
gcloud container clusters get-credentials my-cluster
```

**Features:**
- VPC with IP aliasing
- Regional GKE cluster
- Persistent Disk CSI driver
- GCP Load Balancer
- Workload Identity

---

## 📚 Documentation

- **[DEPLOYMENT.md](DEPLOYMENT.md)** - Complete deployment guide
  - Local testing
  - Cloud infrastructure setup
  - Kubernetes deployment
  - CI/CD integration
  - Troubleshooting

- **[DOCKER_SECURITY.md](DOCKER_SECURITY.md)** - Security best practices
  - Dockerfile hardening explained
  - Security principles
  - Base image recommendations
  - Testing security

- **[infrastructure/README.md](infrastructure/README.md)** - Infrastructure guide
  - Terraform usage
  - Cloud provider setup
  - Cost optimization
  - State management

---

## 🧪 Testing

### Local Testing
```bash
# Backend tests
cd backend
pytest --cov=. --cov-report=html

# Frontend tests
cd frontend
npm test -- --coverage

# Integration tests with Docker Compose
docker-compose up -d
docker-compose exec backend pytest
docker-compose down
```

### Kubernetes Testing
```bash
# Deploy to test namespace
helm install frontend ./charts/frontend -n test --create-namespace

# Run smoke tests
kubectl run test --rm -it --image=curlimages/curl -- \
  curl http://frontend-service.test.svc.cluster.local

# Load testing
kubectl run k6 --rm -it --image=grafana/k6 -- \
  run --vus 10 --duration 30s /scripts/load-test.js
```

---

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

**Branch Protection:**
- All PRs require CI/CD pipeline to pass
- Code review required
- Security scans must pass

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🆘 Support

**Documentation:**
- Deployment issues: See [DEPLOYMENT.md](DEPLOYMENT.md)
- Security questions: See [DOCKER_SECURITY.md](DOCKER_SECURITY.md)
- Infrastructure: See [infrastructure/README.md](infrastructure/README.md)

**Common Issues:**
- ImagePullBackOff: Check image pull secrets
- CrashLoopBackOff: Check pod logs with `kubectl logs`
- Ingress not working: Verify ingress controller installation
- Database connection: Check network policies and secrets

**Get Help:**
- GitHub Issues: Report bugs and request features
- GitHub Discussions: Ask questions and share ideas

---

## ✅ Production Checklist

Before deploying to production:

- [ ] Update all `example.com` domains with your actual domains
- [ ] Configure TLS certificates with cert-manager
- [ ] Set up External Secrets Operator with your secret backend
- [ ] Configure monitoring alerts (Prometheus Alertmanager)
- [ ] Set up log aggregation
- [ ] Review and adjust resource limits
- [ ] Enable network policies
- [ ] Configure backup strategy for PostgreSQL
- [ ] Set up DNS records
- [ ] Review security policies
- [ ] Configure autoscaling thresholds
- [ ] Set up disaster recovery plan

---

## 🎯 Roadmap

- [x] Complete Helm charts with best practices
- [x] Multi-cloud Terraform modules
- [x] Security hardened Dockerfiles
- [x] Automated CI/CD pipeline
- [x] Network policies
- [ ] Service mesh integration (Istio/Linkerd)
- [ ] ArgoCD GitOps setup
- [ ] Multi-region deployment
- [ ] Advanced monitoring with Loki
- [ ] Chaos engineering tests

---

**Built with ❤️ by DevOps Team**

For questions or support, contact: devops@example.com
