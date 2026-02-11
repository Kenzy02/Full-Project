#!/bin/bash
set -e

echo "=========================================="
echo "Cleaning up VPC Dependencies"
echo "=========================================="
echo ""

# Get VPC ID
VPC_ID=$(terraform output -raw vpc_id 2>/dev/null || aws ec2 describe-vpcs --filters "Name=tag:Name,Values=kenzy-eks-vpc" --query "Vpcs[0].VpcId" --output text)
echo "VPC ID: $VPC_ID"

if [ "$VPC_ID" = "None" ] || [ -z "$VPC_ID" ]; then
  echo "VPC not found. Exiting."
  exit 0
fi

# Delete Load Balancers
echo ""
echo "Step 1: Finding and deleting Load Balancers..."
LB_ARNS=$(aws elbv2 describe-load-balancers --query "LoadBalancers[?VpcId=='$VPC_ID'].LoadBalancerArn" --output text)
if [ ! -z "$LB_ARNS" ]; then
  for LB_ARN in $LB_ARNS; do
    echo "  Deleting Load Balancer: $LB_ARN"
    aws elbv2 delete-load-balancer --load-balancer-arn $LB_ARN || true
  done
else
  echo "  No Application/Network Load Balancers found"
fi

# Delete Classic Load Balancers
echo ""
echo "Step 2: Finding and deleting Classic Load Balancers..."
CLB_NAMES=$(aws elb describe-load-balancers --query "LoadBalancerDescriptions[?VPCId=='$VPC_ID'].LoadBalancerName" --output text)
if [ ! -z "$CLB_NAMES" ]; then
  for CLB_NAME in $CLB_NAMES; do
    echo "  Deleting Classic Load Balancer: $CLB_NAME"
    aws elb delete-load-balancer --load-balancer-name $CLB_NAME || true
  done
else
  echo "  No Classic Load Balancers found"
fi

# Wait for load balancers to be deleted
if [ ! -z "$LB_ARNS" ] || [ ! -z "$CLB_NAMES" ]; then
  echo ""
  echo "Waiting 60 seconds for load balancers to be deleted..."
  sleep 60
fi

# Delete NAT Gateways
echo ""
echo "Step 3: Finding and deleting NAT Gateways..."
NAT_IDS=$(aws ec2 describe-nat-gateways --filter "Name=vpc-id,Values=$VPC_ID" "Name=state,Values=available" --query "NatGateways[].NatGatewayId" --output text)
if [ ! -z "$NAT_IDS" ]; then
  for NAT_ID in $NAT_IDS; do
    echo "  Deleting NAT Gateway: $NAT_ID"
    aws ec2 delete-nat-gateway --nat-gateway-id $NAT_ID || true
  done
  echo "  Waiting 120 seconds for NAT Gateways to be deleted..."
  sleep 120
else
  echo "  No NAT Gateways found"
fi

# Release Elastic IPs
echo ""
echo "Step 4: Finding and releasing Elastic IPs..."
EIP_ALLOC_IDS=$(aws ec2 describe-addresses --filters "Name=domain,Values=vpc" --query "Addresses[?AssociationId==null].AllocationId" --output text)
if [ ! -z "$EIP_ALLOC_IDS" ]; then
  for EIP_ID in $EIP_ALLOC_IDS; do
    echo "  Releasing Elastic IP: $EIP_ID"
    aws ec2 release-address --allocation-id $EIP_ID || true
  done
else
  echo "  No unassociated Elastic IPs found"
fi

# Delete Network Interfaces
echo ""
echo "Step 5: Finding and deleting Network Interfaces..."
SUBNET_IDS=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" --query "Subnets[].SubnetId" --output text)
ENI_COUNT=0
for SUBNET_ID in $SUBNET_IDS; do
  ENI_IDS=$(aws ec2 describe-network-interfaces --filters "Name=subnet-id,Values=$SUBNET_ID" --query "NetworkInterfaces[?Description!='ELB *'].NetworkInterfaceId" --output text)
  for ENI_ID in $ENI_IDS; do
    ENI_COUNT=$((ENI_COUNT+1))
    echo "  Processing ENI: $ENI_ID"
    
    # Try to detach if attached
    ATTACHMENT_ID=$(aws ec2 describe-network-interfaces --network-interface-ids $ENI_ID --query "NetworkInterfaces[0].Attachment.AttachmentId" --output text)
    if [ "$ATTACHMENT_ID" != "None" ] && [ ! -z "$ATTACHMENT_ID" ]; then
      echo "    Detaching ENI..."
      aws ec2 detach-network-interface --attachment-id $ATTACHMENT_ID --force || true
      sleep 5
    fi
    
    # Delete the ENI
    echo "    Deleting ENI..."
    aws ec2 delete-network-interface --network-interface-id $ENI_ID || true
  done
done

if [ $ENI_COUNT -eq 0 ]; then
  echo "  No Network Interfaces found"
fi

echo ""
echo "=========================================="
echo "Cleanup Complete!"
echo "=========================================="
echo ""
echo "You can now retry the VPC destroy:"
echo "  terraform destroy -auto-approve -var-file=terraform.tfvars -target=module.vpc"
echo ""
