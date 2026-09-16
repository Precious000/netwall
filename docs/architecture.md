# Netwall Architecture

## Overview

Netwall is a secure AWS network architecture designed around network segmentation, private application infrastructure, controlled administration, monitoring and security automation.

## VPC

CIDR:

10.0.0.0/16

## Network tiers

### Public tier

Public subnets:

- 10.0.1.0/24 - us-east-1a
- 10.0.2.0/24 - us-east-1b

The public tier contains the internet-facing Application Load Balancer.

### Application tier

Private application subnets:

- 10.0.11.0/24 - us-east-1a
- 10.0.12.0/24 - us-east-1b

The application servers do not have public IP addresses.

### Data tier

Private database subnets:

- 10.0.21.0/24 - us-east-1a
- 10.0.22.0/24 - us-east-1b

RDS PostgreSQL is deployed into the private data tier.

### Management tier

Management subnet:

- 10.0.100.0/24 - us-east-1a

Private administration is performed through an EC2 Instance Connect Endpoint.

## Traffic path

Internet
|
v
AWS WAF
|
v
Internet-facing ALB
|
+--> App A
|
+--> App B
|
v
RDS PostgreSQL

## Security controls

- AWS WAF
- Security Groups
- Network ACLs
- VPC Flow Logs
- CloudWatch Logs
- Private application instances
- Private RDS
- EC2 Instance Connect Endpoint
- VPC endpoint
- Lambda security automation

## Design principle

The application servers and database are not directly exposed to the public internet.

Only the intended public entry point is internet-facing.
