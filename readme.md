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
- **Kibana** – Visualization and exploration of Elasticsearch data
- **Logstash** (optional) – Log processing pipeline (can use Fluent Bit instead)
- **Elasticsearch Operator** – Kubernetes operator for managing Elasticsearch clusters

### CI/CD & Version Control
- **Git** for version control and CI/CD
- **CI/CD** – Pipeline automation
- **Docker Compose** for local development

### Security & Quality (DevSecOps)
- **SonarQube** – SAST, code quality, and security hotspots
- **Trivy** – container and dependency vulnerability scanning
- **OWASP dependency-check** (or similar) – SCA for known CVEs
- **AWS Secrets Manager** – No hardcoded secrets; use Secrets Manager or CI variables
- **SAST/DAST** – Static and (optional) dynamic application security testing in the pipeline
- **AWS Security Hub** (optional) – Centralized security findings
- **Slack** – Security and deployment notifications (e.g. failed scans, deploy success)

## Application Architecture

### 1. Web Application
- Flask REST API backend (containerized)
- React frontend (containerized, served via ALB)
- PostgreSQL database (AWS RDS in private subnet)
- Redis cache (AWS ElastiCache in private subnet)
- Unit tests (Jest, pytest)
- API documentation (Swagger)
- **Security:** No secrets in code; dependency scanning; secure defaults (HTTPS, security headers)

### 2. AWS Infrastructure (Terraform)

#### VPC & Networking
- **VPC** with CIDR block (e.g., `10.0.0.0/16`)
- **Public Subnets** (2+ AZs) – ALB, NAT Gateway
- **Private Subnets** (2+ AZs) – EKS nodes, RDS, ElastiCache
- **Database Subnets** (isolated) – RDS PostgreSQL only
- **Internet Gateway** – Public internet access
- **NAT Gateway** – Outbound internet for private subnets
- **Route Tables** – Proper routing between subnets

#### Compute & Orchestration
- **EKS Cluster** – Kubernetes control plane
- **EKS Node Group** – Managed worker nodes (multi-AZ)
- **Application Load Balancer (ALB)** – Routes traffic to EKS services
- **Target Groups** – Backend API and frontend targets

#### Data Layer
- **RDS PostgreSQL** – Multi-AZ, encrypted at rest, in isolated database subnet
- **ElastiCache Redis** – Multi-AZ cluster, encrypted in transit/at rest, in private subnet
- **Security Groups** – Least-privilege access (EKS → RDS, EKS → ElastiCache)

#### Security & Secrets
- **AWS Secrets Manager** – Database credentials, API keys
- **IAM Roles** – EKS service accounts, node groups, ECR access
- **Security Groups** – Network-level security
- **KMS** – Encryption keys for RDS and ElastiCache

#### Monitoring & Observability

**Metrics (Prometheus + Grafana):**
- **Prometheus** – Deployed via kube-prometheus-stack in EKS
  - Scrapes metrics from: EKS nodes (node-exporter), Kubernetes objects (kube-state-metrics), application endpoints
  - Stores time-series metrics for querying and alerting
- **Grafana** – Deployed via kube-prometheus-stack in EKS
  - Connected to Prometheus as data source
  - Pre-built dashboards for Kubernetes, nodes, and applications
  - Custom dashboards for application metrics
- **Alertmanager** – Handles Prometheus alerts and routes to Slack/email
- **Uptime Kuma** – Deployed in EKS as separate deployment
  - Monitors ALB endpoints (frontend and backend)
  - HTTP/HTTPS checks, TCP checks, DNS checks
  - Status page for public visibility
  - Alerts on downtime
- **ServiceMonitors & PodMonitors** – Kubernetes CRDs for Prometheus to discover scrape targets

**Logging & Observability:**

**Option 1: AWS CloudWatch (AWS-native):**
- **Fluent Bit DaemonSet** – Collects logs from all pods and forwards to CloudWatch Logs
- **CloudWatch Log Groups** – Organized by namespace/service (e.g., `/aws/eks/cluster/app-logs`)
- **CloudWatch Logs Insights** – Query logs with SQL-like
- **CloudWatch Alarms** – Alert on log patterns (error rate, exceptions)
- **IAM Roles** – Fluent Bit service account needs CloudWatch Logs write permissions

**Option 2: ELK Stack (Self-hosted on EKS):**
- **Elasticsearch** – Deployed via Elasticsearch Operator or Helm chart
  - Multi-node cluster for high availability
  - Persistent volumes for data retention
- **Fluent Bit DaemonSet** – Collects logs and forwards to Elasticsearch
- **Kibana** – Deployed as Kubernetes Deployment
  - Connected to Elasticsearch as data source
  - Index patterns for log exploration
  - Dashboards for log visualization
- **Logstash** (optional) – For advanced log processing/transformation

## Deliverables

### Code & Configuration
- **Documented Git repository** (README, architecture, how to run and test)
- **Terraform modules** for:
  - VPC & networking (subnets, IGW, NAT, route tables)
  - EKS cluster & node groups
  - RDS PostgreSQL (multi-AZ, encrypted)
  - ElastiCache Redis (multi-AZ, encrypted)
  - ALB & target groups
  - Security groups & IAM roles
  - Secrets Manager secrets
- **Kubernetes manifests** (Deployments, Services, ConfigMaps, Ingress)
  - Application manifests (frontend, backend)
  - Monitoring stack manifests (Prometheus, Grafana, Uptime Kuma)
  - Observability stack manifests (Fluent Bit, CloudWatch/ELK)
  - ServiceMonitors and PrometheusRules for custom metrics
- **Helm charts** or **kubectl manifests** for:
  - kube-prometheus-stack
  - Fluent Bit (CloudWatch or Elasticsearch output)
  - ELK stack (if using self-hosted option)
- **Terraform modules** for:
  - CloudWatch Log Groups (if using AWS CloudWatch)
  - IAM roles for Fluent Bit service account (IRSA)
- **Dockerfile(s)** (multi-stage, non-root, minimal images)
- **Docker Compose** for local development

### CI/CD Pipeline
- **CI/CD pipeline** with DevSecOps stages
- **ECR integration** – Push images to ECR after security scans pass
- **EKS deployment** – Deploy via kubectl or Helm after infrastructure is ready
- **Security:** No hardcoded secrets; use AWS Secrets Manager or CI variables
- **Slack integration** for pipeline and security notifications

### Documentation
- **Architecture diagram** showing:
  - VPC, subnets, ALB, EKS, RDS, ElastiCache
  - Traffic flow
  - Monitoring stack (Prometheus, Grafana, Uptime Kuma)
  - Observability stack (CloudWatch Logs/ELK, Fluent Bit)
  - Where security runs in the pipeline
- **Terraform documentation** (variables, outputs, module structure)
- **Kubernetes deployment guide**
- **Monitoring setup guide** including:
  - kube-prometheus-stack Helm chart installation
  - Prometheus configuration (ServiceMonitors, PrometheusRules)
  - Grafana dashboard setup and data source configuration
  - Uptime Kuma deployment and ALB endpoint configuration
  - Alertmanager notification channels (Slack, email)
- **Observability/Logging setup guide** including:
  - **CloudWatch Option:** Fluent Bit configuration, IAM roles (IRSA), CloudWatch Logs Insights queries
  - **ELK Option:** Elasticsearch cluster deployment, Fluent Bit → Elasticsearch configuration, Kibana setup and dashboards
  - Log collection from application pods
  - Log retention and indexing strategies


*This project demonstrates a full AWS DevSecOps flow: secure code, secure build, secure infrastructure (Terraform), secure deploy (EKS), secure operations, and comprehensive observability.*
