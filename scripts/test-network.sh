#!/bin/bash

set -u

REGION="${AWS_REGION:-us-east-1}"

echo "======================================"
echo " NETWALL NETWORK TEST"
echo "======================================"

echo
echo "[1] Testing ALB..."

ALB_DNS=$(aws elbv2 describe-load-balancers \
  --names netwall-alb \
  --query 'LoadBalancers[0].DNSName' \
  --output text \
  --region "$REGION")

echo "ALB: $ALB_DNS"

curl --connect-timeout 10 -sS "http://$ALB_DNS" || {
    echo "ALB test failed"
}

echo
echo "[2] Checking target health..."

TG_ARN=$(aws elbv2 describe-target-groups \
  --names netwall-targets \
  --query 'TargetGroups[0].TargetGroupArn' \
  --output text \
  --region "$REGION")

aws elbv2 describe-target-health \
  --target-group-arn "$TG_ARN" \
  --query 'TargetHealthDescriptions[].{Instance:Target.Id,Port:Target.Port,State:TargetHealth.State}' \
  --output table \
  --region "$REGION"

echo
echo "[3] Checking RDS..."

aws rds describe-db-instances \
  --db-instance-identifier netwall-data \
  --query 'DBInstances[0].{Status:DBInstanceStatus,Public:PubliclyAccessible,Endpoint:Endpoint.Address,Port:Endpoint.Port}' \
  --output table \
  --region "$REGION"

echo
echo "[4] Checking VPC..."

aws ec2 describe-vpcs \
  --filters "Name=tag:Name,Values=netwall-vpc" \
  --query 'Vpcs[0].{VpcId:VpcId,CIDR:CidrBlock,State:State}' \
  --output table \
  --region "$REGION"

echo
echo "Network test complete."
