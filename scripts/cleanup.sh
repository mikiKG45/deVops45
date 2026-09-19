#!/usr/bin/env bash
# cleanup.sh — deletes resources terraform destroy CANNOT, so destroy can succeed.
# The AWS Load Balancer Controller creates ALBs, target groups and security groups
# OUTSIDE Terraform state; left behind, they block VPC deletion.

set -euo pipefail

REGION="eu-central-1"
PROFILE="devops45"

echo "==> [1/4] Deleting Kubernetes Ingresses (controller removes ALBs gracefully)..."
if kubectl cluster-info >/dev/null 2>&1; then
  kubectl delete ingress --all --all-namespaces --ignore-not-found=true
  echo "    waiting 30s for the controller to delete ALBs..."
  sleep 30
else
  echo "    cluster not reachable, skipping kubectl step."
fi

echo "==> [2/4] Uninstalling the AWS Load Balancer Controller (Helm)..."
helm uninstall aws-load-balancer-controller -n kube-system 2>/dev/null || echo "    already gone."

# Find our VPC by its Name tag.
VPC_ID=$(aws ec2 describe-vpcs --region "$REGION" --profile "$PROFILE" \
  --filters "Name=tag:Name,Values=devops45-dev-vpc" \
  --query "Vpcs[0].VpcId" --output text 2>/dev/null || echo "None")

if [ "$VPC_ID" = "None" ] || [ -z "$VPC_ID" ]; then
  echo "==> VPC not found (already destroyed?). Nothing to clean."
  exit 0
fi
echo "==> Target VPC: $VPC_ID"

echo "==> [3/4] Force-deleting leftover load balancers + target groups in the VPC..."
for LB in $(aws elbv2 describe-load-balancers --region "$REGION" --profile "$PROFILE" \
  --query "LoadBalancers[?VpcId=='$VPC_ID'].LoadBalancerArn" --output text); do
  echo "    deleting LB $LB"
  aws elbv2 delete-load-balancer --load-balancer-arn "$LB" --region "$REGION" --profile "$PROFILE" || true
done
for TG in $(aws elbv2 describe-target-groups --region "$REGION" --profile "$PROFILE" \
  --query "TargetGroups[?VpcId=='$VPC_ID'].TargetGroupArn" --output text); do
  echo "    deleting target group $TG"
  aws elbv2 delete-target-group --target-group-arn "$TG" --region "$REGION" --profile "$PROFILE" 2>/dev/null || true
done

echo "    waiting 20s for load balancer ENIs to detach..."
sleep 20

echo "==> [4/4] Deleting leftover controller-managed security groups (k8s-*)..."
for SG in $(aws ec2 describe-security-groups --region "$REGION" --profile "$PROFILE" \
  --filters "Name=vpc-id,Values=$VPC_ID" \
  --query "SecurityGroups[?starts_with(GroupName, 'k8s-')].GroupId" --output text); do
  # retry a few times: SG deletion fails while ENIs are still detaching
  for attempt in 1 2 3 4 5; do
    if aws ec2 delete-security-group --group-id "$SG" --region "$REGION" --profile "$PROFILE" 2>/dev/null; then
      echo "    deleted SG $SG"
      break
    fi
    echo "    SG $SG still in use, retry $attempt/5 in 15s..."
    sleep 15
  done
done

echo "==> Cleanup done. Now run: terraform destroy"
