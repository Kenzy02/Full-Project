#!/bin/bash
# set -e # Removed to allow the script to continue even if some AWS deletions fail

echo "=========================================="
echo "🚀 Starting Deep Cleanup of VPC Dependencies"
echo "=========================================="

# 1. Get VPC ID and Cluster Name from Terraform Outputs
# We use -no-color and -raw to get clean strings
VPC_ID=$(terraform output -raw vpc_id 2>/dev/null)
CLUSTER_NAME=$(terraform output -raw eks_cluster_name 2>/dev/null)

# Fallback to tags if terraform output fails (e.g. state is partially destroyed)
if [ -z "$VPC_ID" ] || [ "$VPC_ID" == "None" ]; then
    echo "⚠️  Terraform output for vpc_id failed, trying AWS CLI tags..."
    VPC_ID=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=my-eks-cluster-vpc" --query "Vpcs[0].VpcId" --output text)
fi

if [ -z "$VPC_ID" ] || [ "$VPC_ID" == "None" ]; then
    echo "❌ Error: Could not determine VPC_ID. Manual cleanup may be required."
    exit 1
fi

echo "✅ Target VPC: $VPC_ID"
echo "✅ Cluster Name Context: ${CLUSTER_NAME:-'my-eks-cluster'}"

# --- FUNCTION: Delete Load Balancer Resources ---
echo ""
echo "Step 1: Application & Network Load Balancers"
LB_ARNS=$(aws elbv2 describe-load-balancers --query "LoadBalancers[?VpcId=='$VPC_ID'].LoadBalancerArn" --output text)
for LB_ARN in $LB_ARNS; do
    echo "  🗑️  Deleting LB: $LB_ARN"
    aws elbv2 delete-load-balancer --load-balancer-arn $LB_ARN
done

# --- FUNCTION: Delete Target Groups ---
echo ""
echo "Step 2: Target Groups"
TG_ARNS=$(aws elbv2 describe-target-groups --query "TargetGroups[?VpcId=='$VPC_ID'].TargetGroupArn" --output text)
for TG_ARN in $TG_ARNS; do
    echo "  🗑️  Deleting Target Group: $TG_ARN"
    aws elbv2 delete-target-group --target-group-arn $TG_ARN
done

# --- FUNCTION: Wait for LB Deletion ---
if [ ! -z "$LB_ARNS" ]; then
    echo "⏳ Waiting 30s for Load Balancers to fully release ENIs..."
    sleep 30
fi

# --- FUNCTION: Security Groups ---
echo ""
echo "Step 3: Security Groups (Deleting all non-default)"
SG_IDS=$(aws ec2 describe-security-groups --filters "Name=vpc-id,Values=$VPC_ID" --query "SecurityGroups[?GroupName!='default'].GroupId" --output text)
for SG_ID in $SG_IDS; do
    echo "  🗑️  Deleting Security Group: $SG_ID"
    # We try up to 3 times because SG deletion often fails if ENIs are still detaching
    for i in {1..3}; do
        if aws ec2 delete-security-group --group-id $SG_ID 2>/dev/null; then
            echo "    ✅ Success"
            break
        else
            echo "    ⏳ Retry $i/3 (Still in use...)"
            sleep 10
        fi
    done
done

# --- FUNCTION: NAT Gateways ---
echo ""
echo "Step 4: NAT Gateways"
NAT_IDS=$(aws ec2 describe-nat-gateways --filter "Name=vpc-id,Values=$VPC_ID" "Name=state,Values=available" --query "NatGateways[].NatGatewayId" --output text)
for NAT_ID in $NAT_IDS; do
    echo "  🗑️  Deleting NAT Gateway: $NAT_ID"
    aws ec2 delete-nat-gateway --nat-gateway-id $NAT_ID
done

# --- FUNCTION: Network Interfaces (ENIs) ---
echo ""
echo "Step 5: Network Interfaces (Zombie ENIs)"
ENI_IDS=$(aws ec2 describe-network-interfaces --filters "Name=vpc-id,Values=$VPC_ID" --query "NetworkInterfaces[?Status!='deleted'].NetworkInterfaceId" --output text)
for ENI_ID in $ENI_IDS; do
    echo "  🗑️  Cleaning up ENI: $ENI_ID"
    aws ec2 delete-network-interface --network-interface-id $ENI_ID 2>/dev/null || echo "    ⚠️  Could not delete (Skip)"
done

echo ""
echo "=========================================="
echo "🎉 Cleanup Run Finished"
echo "=========================================="
