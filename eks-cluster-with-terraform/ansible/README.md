# Ansible Playbook - Infrastructure Tools Setup

This Ansible playbook automates the installation and deployment of security, cost optimization, and GitOps tools for your EKS infrastructure.

## Tools Included

### CLI Tools (Installed on Control Machine)
- **Checkov** - Infrastructure-as-Code security scanner
- **tfsec** - Terraform static analysis for security
- **TFLint** - Terraform linter for best practices
- **Infracost** - Cloud cost estimation for Terraform

### AWS Services
- **CloudTrail** - Audit logging for AWS API calls

### Kubernetes Applications (Deployed to EKS)
- **Kyverno** - Policy engine for Kubernetes security and compliance
- **ArgoCD** - GitOps continuous delivery tool

## Prerequisites

1. **Ansible installed** (version 2.10+)
   ```bash
   pip install ansible
   ```

2. **AWS CLI configured** with appropriate credentials
   ```bash
   aws configure
   ```

3. **kubectl installed** and configured
   ```bash
   aws eks update-kubeconfig --name kenzy-eks-cluster --region us-east-1
   ```

4. **Helm installed** (version 3+)
   ```bash
   curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
   ```

5. **Python packages**
   ```bash
   pip install boto3 kubernetes openshift
   ```

## Installation Steps

### 1. Install Ansible Collections
```bash
cd ansible
ansible-galaxy collection install -r requirements.yml
```

### 2. Configure Variables
Edit `group_vars/all.yml` to customize:
- AWS region and EKS cluster name
- Tool versions
- Storage sizes
- ArgoCD admin password (IMPORTANT: change default!)

### 3. Run the Playbook

**Full deployment:**
```bash
ansible-playbook -i inventory/hosts.ini playbook.yml
```

**Run specific components using tags:**
```bash
# Install CLI tools only
ansible-playbook -i inventory/hosts.ini playbook.yml --tags "checkov,tfsec,tflint,infracost"

# Deploy Kyverno only
ansible-playbook -i inventory/hosts.ini playbook.yml --tags kyverno

# Deploy ArgoCD only
ansible-playbook -i inventory/hosts.ini playbook.yml --tags argocd

# Configure CloudTrail only
ansible-playbook -i inventory/hosts.ini playbook.yml --tags cloudtrail
```

## Post-Deployment Configuration

### 1. Configure Infracost
```bash
infracost auth login
# Or set API key manually
export INFRACOST_API_KEY=your-api-key
```

### 2. Access ArgoCD
Get the LoadBalancer URL:
```bash
kubectl get svc argocd-server -n argocd
```

Get admin password:
```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

Login:
- **Username:** admin
- **Password:** (from above command)

### 3. Access Kibana
Get the LoadBalancer URL:
```bash
kubectl get svc kibana-kibana -n logging
```

Access via browser at the LoadBalancer endpoint.

### 4. Verify Kyverno
Check Kyverno policies:
```bash
kubectl get clusterpolicy
kubectl get policy -A
```

## Usage Examples

### Scan Terraform Code with Checkov
```bash
cd /path/to/terraform
checkov -d . --framework terraform
```

### Scan with tfsec
```bash
cd /path/to/terraform
tfsec .
```

### Lint Terraform with TFLint
```bash
cd /path/to/terraform
tflint
```

### Generate Cost Estimate with Infracost
```bash
cd /path/to/terraform
infracost breakdown --path .
```

### View CloudTrail Logs
```bash
aws cloudtrail lookup-events --region us-east-1
```

## Troubleshooting

### Issue: kubectl not configured
```bash
aws eks update-kubeconfig --name main-eks-cluster --region us-east-1
```

### Issue: Helm not found
```bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

### Issue: ArgoCD pods not starting
Check pod status:
```bash
kubectl get pods -n argocd
kubectl logs -n argocd <pod-name>
```

### Issue: Elasticsearch pods pending
Check persistent volume claims:
```bash
kubectl get pvc -n logging
```

Ensure your EKS cluster has a storage class:
```bash
kubectl get storageclass
```

## Uninstalling

Remove deployed applications:
```bash
# Remove ArgoCD
kubectl delete namespace argocd

# Remove Kyverno
helm uninstall kyverno -n kyverno
kubectl delete namespace kyverno

# Disable CloudTrail
aws cloudtrail delete-trail --name kenzy-eks-audit-trail --region us-east-1
```

## Security Considerations

1. **Change default passwords** in `group_vars/all.yml`
2. **Use AWS Secrets Manager** or **HashiCorp Vault** for sensitive data
3. **Enable RBAC** in EKS cluster
4. **Restrict S3 bucket access** for CloudTrail logs
5. **Enable encryption** for all Kubernetes secrets
6. **Use network policies** with Kyverno

## Integration with CI/CD

Add to your Azure Pipeline before Terraform apply:
```yaml
- script: |
    checkov -d . --framework terraform --output junitxml > checkov-report.xml
    tfsec . --format junit > tfsec-report.xml
  displayName: 'Security Scanning'
  
- script: |
    infracost breakdown --path . --format json --out-file infracost.json
  displayName: 'Cost Estimation'
```

## Support

For issues or questions:
- Checkov: https://github.com/bridgecrewio/checkov
- tfsec: https://github.com/aquasecurity/tfsec
- Infracost: https://github.com/infracost/infracost
- Kyverno: https://kyverno.io/docs/
- ArgoCD: https://argo-cd.readthedocs.io/

## License

MIT
