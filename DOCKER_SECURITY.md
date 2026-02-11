# Dockerfile Security Best Practices

This document explains the security measures implemented in our Dockerfiles and why they matter.

## Overview

Our Dockerfiles follow industry security best practices including:
- Multi-stage builds to minimize attack surface
- Running as non-root users
- Read-only root filesystem where possible
- Minimal base images
- No hardcoded secrets
- Security updates applied

## Frontend Dockerfile Security

### 1. Multi-Stage Build
**Why**: Separates build environment from runtime, reducing final image size and attack surface.
```dockerfile
FROM node:18-alpine AS build  # Build stage
FROM nginx:1.25-alpine        # Runtime stage (smaller, fewer vulnerabilities)
```

### 2. Non-Root User
**Why**: Prevents privilege escalation attacks. Even if an attacker compromises the container, they can't gain root access.
```dockerfile
USER nginx  # Runs nginx as user ID 101, not root (0)
```

### 3. Non-Privileged Port
**Why**: Ports below 1024 require root privileges. Using 8080 allows non-root execution.
```dockerfile
EXPOSE 8080  # Instead of 80
```

### 4. Read-Only Root Filesystem
**Why**: Prevents attackers from modifying system files or planting malware.
```dockerfile
VOLUME ["/var/cache/nginx", "/var/run"]  # Only these directories are writable
```

### 5. Minimal Base Image
**Why**: Alpine Linux has fewer packages = fewer potential vulnerabilities.
```dockerfile
FROM nginx:1.25-alpine  # ~5MB base vs ~100MB for Debian
```

### 6. Security Updates
**Why**: Patches known vulnerabilities in OS packages.
```dockerfile
RUN apk upgrade --no-cache
```

### 7. Health Checks
**Why**: Kubernetes can detect and restart unhealthy containers.
```dockerfile
HEALTHCHECK CMD curl -f http://localhost:8080/ || exit 1
```

## Backend Dockerfile Security

### 1. Multi-Stage Build
**Why**: Build dependencies (gcc, build-tools) aren't needed in production.
```dockerfile
FROM python:3.11-slim AS builder  # Build wheels with gcc
FROM python:3.11-slim             # Production without build tools
```

### 2. Virtual Environment
**Why**: Isolates dependencies, prevents conflicts, easier to copy between stages.
```dockerfile
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"
```

### 3. Non-Root User
**Why**: Same as frontend - prevents privilege escalation.
```dockerfile
USER appuser  # UID 1000, not root
```

### 4. Production WSGI Server
**Why**: Flask's built-in server is NOT production-ready. Gunicorn handles:
- Multiple worker processes
- Request timeouts
- Graceful shutdowns
- Better performance

```dockerfile
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "--workers", "4", "app:app"]
```

### 5. Environment Variables
**Why**: Optimize Python behavior for containers.
```dockerfile
ENV PYTHONUNBUFFERED=1          # Don't buffer stdout (see logs immediately)
ENV PYTHONDONTWRITEBYTECODE=1   # Don't create .pyc files (read-only filesystem)
ENV PYTHONHASHSEED=random       # Security: randomize hash seeds
```

### 6. Dependency Pinning
**Why**: Ensures reproducible builds, prevents supply chain attacks.
```
Flask==2.3.3  # Exact version, not Flask>=2.0
```

## Common Security Principles

### 1. No Secrets in Images
**NEVER** do this:
```dockerfile
ENV DATABASE_PASSWORD=mysecret  # ❌ WRONG - visible in image layers
COPY .env .                      # ❌ WRONG - secrets in image
```

**ALWAYS** use Kubernetes Secrets:
```yaml
env:
  - name: DATABASE_PASSWORD
    valueFrom:
      secretKeyRef:
        name: backend-secret
        key: password
```

### 2. Layer Caching Optimization
**Why**: Faster builds, less network usage.
```dockerfile
COPY package.json .      # Copy dependency files first
RUN npm install          # This layer cached if package.json unchanged
COPY . .                 # Source code changes don't invalidate npm install
```

### 3. Minimal Dependencies
**Why**: Each package is a potential vulnerability.
```dockerfile
RUN apt-get install --no-install-recommends  # Don't install suggested packages
```

### 4. Cleanup
**Why**: Reduces image size and removes temporary files that might contain sensitive data.
```dockerfile
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
```

## Kubernetes Security Integration

These Dockerfile features work with Kubernetes security contexts:

```yaml
# In your Helm chart deployment.yaml
securityContext:
  runAsNonRoot: true          # Enforces USER directive in Dockerfile
  runAsUser: 1000             # Must match Dockerfile USER
  readOnlyRootFilesystem: true  # Enforces VOLUME-only writes
  allowPrivilegeEscalation: false  # Prevent sudo/setuid
  capabilities:
    drop:
      - ALL                   # Drop all Linux capabilities
```

## Vulnerability Scanning

Our CI/CD pipeline scans images with Trivy:

```yaml
- name: Run Trivy scanner
  uses: aquasecurity/trivy-action@master
  with:
    severity: 'CRITICAL,HIGH'
    exit-code: '1'  # Fail build on HIGH/CRITICAL
```

## Base Image Recommendations

### Current Setup (Good)
- `node:18-alpine` - small, regularly updated
- `python:3.11-slim` - Debian-based, smaller than full Python image
- `nginx:1.25-alpine` - minimal web server

### Even Better (Advanced)
- **Distroless**: Google's minimal images with no shell
  ```dockerfile
  FROM gcr.io/distroless/python3-debian11
  # No package manager, no shell = minimal attack surface
  ```
- **Chainguard**: Hardened, minimal images
  ```dockerfile
  FROM cgr.dev/chainguard/python:latest
  ```

## Testing Security

### Local Testing
```bash
# Test as non-root
docker run --user 1000:1000 myimage

# Test read-only filesystem
docker run --read-only --tmpfs /tmp myimage

# Scan for vulnerabilities
docker scan myimage
trivy image myimage
```

### Kubernetes Testing
```bash
# Deploy with restricted PSP/PSS
kubectl label namespace dev pod-security.kubernetes.io/enforce=restricted
```

## References

- [CIS Docker Benchmark](https://www.cisecurity.org/benchmark/docker)
- [OWASP Docker Security](https://cheatsheetseries.owasp.org/cheatsheets/Docker_Security_Cheat_Sheet.html)
- [Kubernetes Pod Security Standards](https://kubernetes.io/docs/concepts/security/pod-security-standards/)
