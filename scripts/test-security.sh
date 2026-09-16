#!/bin/bash

set -u

REGION="${AWS_REGION:-us-east-1}"

echo "======================================"
echo " NETWALL SECURITY TEST"
echo "======================================"

echo
echo "[1] WAF Web ACLs"

aws wafv2 list-web-acls \
  --scope REGIONAL \
  --region "$REGION" \
  --query 'WebACLs[].{Name:Name,Id:Id,ARN:ARN}' \
  --output table

echo
echo "[2] VPC Flow Logs"

aws ec2 describe-flow-logs \
  --filter "Name=resource-id,Values=$(aws ec2 describe-vpcs \
    --filters "Name=tag:Name,Values=netwall-vpc" \
    --query 'Vpcs[0].VpcId' \
    --output text \
    --region "$REGION")" \
  --query 'FlowLogs[].{Id:FlowLogId,Status:FlowLogStatus,Traffic:TrafficType,Group:LogGroupName}' \
  --output table \
  --region "$REGION"

echo
echo "[3] RDS public accessibility"

aws rds describe-db-instances \
  --db-instance-identifier netwall-data \
  --query 'DBInstances[0].PubliclyAccessible' \
  --output text \
  --region "$REGION"

echo
echo "[4] App Security Group"

aws ec2 describe-security-groups \
  --group-ids sg-038021fa4a0dff9d1 \
  --query 'SecurityGroups[0].IpPermissions[].{Protocol:IpProtocol,From:FromPort,To:ToPort,SourceSG:UserIdGroupPairs[].GroupId,CIDR:IpRanges[].CidrIp}' \
  --output table \
  --region "$REGION"

echo
echo "Security test complete."
