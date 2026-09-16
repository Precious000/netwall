#!/bin/bash

set -u

REGION="${AWS_REGION:-us-east-1}"

echo "======================================"
echo " NETWALL RESOURCE CHECK"
echo "======================================"

echo
echo "VPC"
aws ec2 describe-vpcs \
  --filters "Name=tag:Name,Values=netwall-vpc" \
  --query 'Vpcs[].{Id:VpcId,CIDR:CidrBlock,State:State}' \
  --output table \
  --region "$REGION"

echo
echo "SUBNETS"
aws ec2 describe-subnets \
  --filters "Name=vpc-id,Values=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=netwall-vpc" --query 'Vpcs[0].VpcId' --output text --region "$REGION")" \
  --query 'Subnets[].{Name:Tags[?Key==`Name`]|[0].Value,Subnet:SubnetId,CIDR:CidrBlock,AZ:AvailabilityZone}' \
  --output table \
  --region "$REGION"

echo
echo "APPLICATION INSTANCES"
aws ec2 describe-instances \
  --instance-ids \
    i-0022daba01567cc01 \
    i-0a6d18a6f27138ea3 \
  --query 'Reservations[].Instances[].{Id:InstanceId,PrivateIP:PrivateIpAddress,State:State.Name,Subnet:SubnetId}' \
  --output table \
  --region "$REGION"

echo
echo "ALB"
aws elbv2 describe-load-balancers \
  --names netwall-alb \
  --query 'LoadBalancers[].{Name:LoadBalancerName,State:State.Code,DNS:DNSName}' \
  --output table \
  --region "$REGION"

echo
echo "RDS"
aws rds describe-db-instances \
  --db-instance-identifier netwall-data \
  --query 'DBInstances[].{Identifier:DBInstanceIdentifier,Status:DBInstanceStatus,Engine:Engine,Public:PubliclyAccessible}' \
  --output table \
  --region "$REGION"

echo
echo "EICE"
aws ec2 describe-instance-connect-endpoints \
  --instance-connect-endpoint-ids eice-0b458a8a4dcb81ed4 \
  --query 'InstanceConnectEndpoints[].{Id:InstanceConnectEndpointId,State:State,Subnet:SubnetId,VPC:VpcId}' \
  --output table \
  --region "$REGION"

echo
echo "RESOURCE CHECK COMPLETE"
