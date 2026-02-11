#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export PATH="/usr/local/bin:$PATH"
cd "$SCRIPT_DIR"

echo "=========================================="
echo "Ansible Infrastructure Tools Setup"
echo "=========================================="
echo ""

# Check prerequisites
echo "Checking prerequisites..."

if ! command -v ansible &> /dev/null; then
    echo "❌ Ansible not found. Installing..."
    pip install ansible
else
    echo "✅ Ansible installed: $(ansible --version | head -n1)"
fi

if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI not found. Please install it first."
    exit 1
else
    echo "✅ AWS CLI installed: $(aws --version)"
fi

if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl not found. Please install it first."
    exit 1
else
    echo "✅ kubectl installed: $(kubectl version --client --short 2>/dev/null || kubectl version --client)"
fi

DESIRED_HELM_VERSION="v3.14.4"
if ! command -v helm &> /dev/null; then
    echo "⚠️  Helm not found. Installing ${DESIRED_HELM_VERSION}..."
    DESIRED_VERSION="${DESIRED_HELM_VERSION}" curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
else
    HELM_VERSION_OUTPUT="$(helm version --short 2>/dev/null || true)"
    if echo "$HELM_VERSION_OUTPUT" | grep -q "^v3\."; then
        echo "✅ Helm installed: $HELM_VERSION_OUTPUT"
    else
        echo "⚠️  Helm version is not v3. Installing ${DESIRED_HELM_VERSION} to /usr/local/bin..."
        DESIRED_VERSION="${DESIRED_HELM_VERSION}" curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    fi
fi

echo ""
echo "Installing required Python packages in a virtual environment..."
VENV_DIR="$SCRIPT_DIR/.venv"
if [ ! -d "$VENV_DIR" ]; then
    python3 -m venv "$VENV_DIR"
fi
"$VENV_DIR/bin/pip" install --upgrade pip -q
"$VENV_DIR/bin/pip" install packaging boto3 kubernetes openshift -q

echo ""
echo "Installing Ansible collections..."
ansible-galaxy collection install -r requirements.yml

echo ""
echo "Configuring kubectl for EKS..."
aws eks update-kubeconfig --name kenzy-eks-cluster --region us-east-1

echo ""
echo "=========================================="
echo "Setup Complete!"
echo "=========================================="
echo ""
echo "To run the playbook:"
echo "  ansible-playbook -i inventory/hosts.ini playbook.yml"
echo ""
echo "To run specific tools only:"
echo "  ansible-playbook -i inventory/hosts.ini playbook.yml --tags checkov,tfsec"
echo ""
echo "For more information, see README.md"
echo ""
