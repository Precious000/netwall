# Netwall Traffic Flow

## 1. Internet to application

A client connects to the public ALB.

Traffic flow:

Client
|
v
Internet Gateway
|
v
ALB
|
v
Target Group
|
+--> App A:8080
|
+--> App B:8080

The ALB distributes requests between healthy application targets.

## 2. Application to database

Application instances communicate with RDS over TCP 5432.

App
|
v
App Security Group
|
v
RDS Security Group
|
v
PostgreSQL:5432

The RDS database is not publicly accessible.

## 3. Application-to-application

App A and App B are located in private subnets.

They can communicate using their private IP addresses when permitted by routing and security controls.

## 4. Administration

Administrators do not connect directly from the internet to the private application instances.

The intended private administration path is:

Administrator
|
v
EC2 Instance Connect Endpoint
|
v
Private App Instance

## 5. Network monitoring

VPC traffic metadata is captured through VPC Flow Logs.

VPC
|
v
VPC Flow Logs
|
v
CloudWatch Logs
|
v
Security analysis

## 6. Security-group drift

A security-group modification can generate an AWS API event.

EventBridge can detect the event and invoke the drift detector Lambda.

Security Group Change
|
v
CloudTrail event
|
v
EventBridge
|
v
Drift Detector Lambda
|
v
Validate intended configuration
|
v
Remove unauthorized rule
