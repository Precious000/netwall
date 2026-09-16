# Netwall — AWS Cloud Network & Security Architecture

Netwall is a hands-on AWS networking and security project focused on designing a secure, segmented, and observable cloud environment.

The project demonstrates how to build a multi-tier AWS architecture from the ground up, control communication between different network tiers, expose applications securely through a load balancer, protect web traffic with AWS WAF, keep databases private, and monitor network and infrastructure activity.

The project is built manually through the AWS Management Console to develop a practical understanding of how the individual AWS networking components work together.

---

## Project Goals

Netwall was designed to demonstrate the following:

* AWS VPC architecture
* Network segmentation
* Public and private subnets
* Route tables and routing
* Internet Gateway
* NAT Gateway
* Security Groups
* Network ACLs
* Application Load Balancer
* AWS WAF
* Private EC2 application servers
* Private RDS PostgreSQL
* Multi-AZ architecture
* VPC Flow Logs
* CloudWatch monitoring
* CloudTrail
* EventBridge
* Lambda-based security detection
* SNS security alerts
* Private DNS with Route 53
* Network troubleshooting
* Security testing and validation

---

# Architecture

```text
                              INTERNET
                                  |
                                  v
                            +-----------+
                            |  AWS WAF  |
                            +-----+-----+
                                  |
                                  v
                         +----------------+
                         |      ALB       |
                         | Internet-facing|
                         +-------+--------+
                                 |
                    +------------+------------+
                    |                         |
                    v                         v
             +-------------+           +-------------+
             |   App-A     |           |   App-B     |
             |  AZ-A       |           |  AZ-B       |
             | 10.0.11.x   |           | 10.0.12.x   |
             +------+------+           +------+------+
                    |                         |
                    +------------+------------+
                                 |
                              TCP 5432
                                 |
                                 v
                         +----------------+
                         | RDS PostgreSQL |
                         |   Private DB   |
                         +-------+--------+
                                 |
                    +------------+------------+
                    |                         |
                    v                         v
              Data-A / AZ-A            Data-B / AZ-B
              10.0.21.0/24             10.0.22.0/24
```

Management access:

```text
                         ADMIN
                           |
                           v
                    +-------------+
                    |   Bastion   |
                    | Management  |
                    +------+------+
                           |
                    +------+------+
                    |             |
                    v             v
                  App EC2       RDS
```

Private application outbound traffic:

```text
                    App EC2
                       |
                       v
                 NAT Gateway
                       |
                       v
                Internet Gateway
                       |
                       v
                    INTERNET
```

Monitoring and security detection:

```text
VPC Flow Logs
      |
      v
 CloudWatch


CloudTrail
    |
    v
EventBridge
    |
    v
 Lambda
    |
    v
   SNS
    |
    v
Security Alert
```

---

# 1. VPC

The project uses a dedicated VPC:

```text
VPC CIDR: 10.0.0.0/16
```

The VPC provides the isolated network environment for all Netwall resources.

DNS resolution and DNS hostnames are enabled to support AWS service discovery and private DNS.

---

# 2. Network Segmentation

The VPC is divided into separate network tiers.

| Tier       | Subnet      | CIDR            | Purpose                       |
| ---------- | ----------- | --------------- | ----------------------------- |
| Public-A   | Public      | `10.0.1.0/24`   | Internet-facing resources     |
| Public-B   | Public      | `10.0.2.0/24`   | Internet-facing resources     |
| App-A      | Application | `10.0.11.0/24`  | Private application workloads |
| App-B      | Application | `10.0.12.0/24`  | Private application workloads |
| Data-A     | Database    | `10.0.21.0/24`  | Database resources            |
| Data-B     | Database    | `10.0.22.0/24`  | Database resources            |
| Management | Management  | `10.0.100.0/24` | Administrative access         |

The separation prevents all workloads from existing in the same network segment.

The application and database tiers are not directly exposed to the public internet.

---

# 3. Internet Gateway

An Internet Gateway is attached to the VPC.

The public route table contains:

```text
Destination: 0.0.0.0/0
Target: Internet Gateway
```

The route table is associated with the public subnets.

This allows resources that are intentionally placed in the public tier to communicate with the internet.

An Internet Gateway alone does not make an instance public. The subnet route table and the instance's public addressing must also support internet connectivity.

---

# 4. NAT Gateway

A NAT Gateway is deployed in a public subnet.

Private application subnets use the NAT Gateway for outbound internet access.

```text
Private App EC2
      |
      v
NAT Gateway
      |
      v
Internet Gateway
      |
      v
Internet
```

This allows application servers to reach external services without assigning them public IP addresses.

The application instances therefore remain private while still being able to perform required outbound connections.

---

# 5. Route Tables

Separate route tables are used to control traffic for the different network tiers.

### Public Route Table

```text
0.0.0.0/0 → Internet Gateway
```

Associated with:

```text
Public-A
Public-B
```

### Application Route Tables

```text
0.0.0.0/0 → NAT Gateway
```

Associated with:

```text
App-A
App-B
```

### Data Route Tables

The database subnets do not have a direct internet route.

This keeps the database tier isolated from direct internet access.

### Management Route Table

The management subnet is separated from the application and database tiers so that administrative access can be controlled independently.

---

# 6. Security Groups

Security Groups provide workload-level traffic control.

The planned security groups are:

```text
Netwall-ALB-SG
Netwall-App-SG
Netwall-DB-SG
Netwall-Management-SG
```

The intended communication model is:

```text
Internet
    |
    v
ALB-SG
    |
    | TCP 8080
    v
App-SG
    |
    | TCP 5432
    v
DB-SG
```

Management traffic follows a separate path:

```text
Management-SG
      |
      | TCP 22
      v
App-SG
```

The database does not accept PostgreSQL traffic from the public internet.

Instead, its intended source is the application security group.

This demonstrates the principle of restricting access to the resources that actually require it.

---

# 7. Bastion Host

A bastion host is used as a controlled administrative entry point for the lab.

The bastion is located in the management subnet.

The intended access path is:

```text
Administrator
     |
     v
Bastion
     |
     v
Private App EC2
```

The application instances do not require public IP addresses.

For production environments, AWS Systems Manager Session Manager would generally be preferred over maintaining a publicly reachable SSH bastion.

---

# 8. Application EC2 Instances

The application tier contains private EC2 instances.

```text
Netwall-App-A
    |
    +-- App subnet A
        10.0.11.0/24


Netwall-App-B
    |
    +-- App subnet B
        10.0.12.0/24
```

The application listens on:

```text
TCP 8080
```

The application instances are not directly exposed to the internet.

Traffic reaches them through the Application Load Balancer.

---

# 9. Application Load Balancer

An internet-facing Application Load Balancer provides the public entry point to the application.

Traffic flow:

```text
Client
  |
  v
ALB
  |
  +----> App-A :8080
  |
  +----> App-B :8080
```

The ALB performs health checks against the application instances.

If an instance becomes unhealthy, the ALB can stop sending traffic to that instance.

Using two application subnets in different Availability Zones also provides a foundation for high availability.

---

# 10. RDS PostgreSQL

The database tier uses Amazon RDS PostgreSQL.

The database is deployed using a DB subnet group containing:

```text
Data-A
Data-B
```

The database is configured with:

```text
Public access: No
Port: 5432
```

The intended traffic path is:

```text
Application EC2
      |
      | TCP 5432
      v
RDS PostgreSQL
```

Direct internet access to the database is not permitted.

---

# 11. AWS WAF

AWS WAF is associated with the Application Load Balancer.

The WAF provides an additional security layer before requests reach the application.

The project uses managed protection rules and rate-based protection.

Conceptually:

```text
Internet
   |
   v
 AWS WAF
   |
   | Allowed requests
   v
   ALB
   |
   v
Application
```

Blocked requests can be monitored through AWS monitoring tools.

---

# 12. VPC Flow Logs

VPC Flow Logs provide visibility into network traffic.

They can be used to investigate:

* Source IP
* Destination IP
* Source port
* Destination port
* Protocol
* Accepted traffic
* Rejected traffic

The flow logs are sent to CloudWatch Logs.

This becomes particularly useful when troubleshooting connectivity problems.

For example:

```text
App EC2
   |
   X
RDS :5432
```

If the connection fails, Flow Logs can help determine whether traffic is being accepted or rejected.

---

# 13. CloudTrail

AWS CloudTrail records API activity within the AWS environment.

It provides visibility into changes made to AWS resources.

For example, a Security Group modification can generate a CloudTrail event.

This provides an audit trail for infrastructure changes.

---

# 14. Security Group Drift Detection

Netwall uses AWS security events to demonstrate automated detection of unexpected Security Group changes.

The intended architecture is:

```text
Security Group Change
        |
        v
    CloudTrail
        |
        v
    EventBridge
        |
        v
      Lambda
        |
        v
Compare against
approved policy
        |
        v
      SNS
        |
        v
Security Alert
```

The initial approach focuses on **detecting and reporting unexpected changes** rather than automatically deleting them.

This reduces the risk of an automated remediation system accidentally breaking legitimate connectivity.

---

# 15. CloudWatch Monitoring

CloudWatch is used to monitor the environment.

Important metrics include:

### ALB

* Request count
* Response time
* Healthy hosts
* Unhealthy hosts
* HTTP 5xx responses

### EC2

* CPU utilization
* Network traffic
* Instance health

### RDS

* CPU utilization
* Database connections
* Storage
* Availability

### WAF

* Allowed requests
* Blocked requests

The objective is to make the environment observable rather than relying only on manual investigation.

---

# 16. Route 53 Private DNS

A private Route 53 hosted zone can be associated with the Netwall VPC.

Example:

```text
internal.netwall.local
```

Internal records can then be created for private services.

Example:

```text
app.internal.netwall.local
```

This provides private DNS-based service discovery within the VPC.

---

# 17. Network ACLs

Network ACLs provide an additional subnet-level security layer.

Unlike Security Groups, Network ACLs are **stateless**.

Therefore, both directions of communication need to be considered.

For example:

```text
Request
   ↓
Subnet
   ↓
Application
   ↓
Response
   ↑
Subnet
```

The return traffic must also be permitted by the appropriate NACL rules.

NACLs are introduced carefully because overly restrictive rules can unintentionally break legitimate traffic.

---

# 18. Traffic Validation

The architecture is validated by testing both permitted and denied traffic.

### Expected allowed traffic

```text
Internet → WAF → ALB
ALB → App :8080
App → RDS :5432
App → Internet → NAT Gateway
Management → App :22
```

### Expected denied traffic

```text
Internet → App :8080
Internet → RDS :5432
Unauthorized → App :22
Unauthorized → RDS :5432
```

The goal is not simply to create resources but to prove that the network behaves according to the intended security policy.

---

# 19. Troubleshooting Method

Netwall uses a structured packet-path troubleshooting process.

When connectivity fails, the following sequence is checked:

```text
1. Is the source instance running?
2. Is the destination instance/service running?
3. Is DNS resolving correctly?
4. What is the source IP?
5. What is the destination IP?
6. Which subnet is the source in?
7. Which route table is associated with the source subnet?
8. Does the route table contain the correct route?
9. Does the source Security Group allow the traffic?
10. Does the destination Security Group allow the traffic?
11. Are NACLs allowing the traffic?
12. Is the destination service listening on the expected port?
13. Is the return path available?
14. What do VPC Flow Logs show?
```

For example, when testing:

```bash
nc -vz <private-ip> 22
```

the test verifies whether a TCP connection can be established to port 22.

If it fails, the failure should be investigated through the network path rather than immediately changing random security rules.

---

# 20. Failure Testing

The project deliberately introduces controlled failures to validate troubleshooting skills.

For example, removing the application-to-database rule:

```text
App-SG
   X
DB-SG :5432
```

should cause the database connection to fail.

The rule can then be restored and connectivity validated again.

Other possible tests include:

* Removing an ALB-to-App rule
* Blocking traffic with a NACL
* Removing a route
* Stopping an application instance
* Making an ALB target unhealthy
* Modifying a Security Group unexpectedly

Each test demonstrates how different network layers affect connectivity.

---

# 21. Security Model

The overall security model can be summarized as:

```text
                  INTERNET
                     |
                     v
                    WAF
                     |
                     v
                    ALB
                     |
                     v
              PRIVATE APP TIER
                     |
                     v
              PRIVATE DB TIER
```

Administrative access is separated:

```text
ADMIN
  |
  v
MANAGEMENT
  |
  v
PRIVATE WORKLOADS
```

Monitoring surrounds the environment:

```text
Network Traffic → VPC Flow Logs → CloudWatch

AWS Changes → CloudTrail → EventBridge → Lambda → SNS
```

---

# 22. Design Principles

Netwall follows several core principles.

### Least Privilege

Only required traffic should be permitted.

### Network Segmentation

Different workloads are separated into different network tiers.

### Private by Default

Application and database workloads should not require public IP addresses.

### Controlled Internet Access

Private workloads use controlled outbound paths through NAT.

### Defense in Depth

Security is implemented at multiple layers:

```text
WAF
 ↓
ALB
 ↓
Security Groups
 ↓
NACLs
 ↓
Private Subnets
 ↓
RDS
```

### Observability

Network and infrastructure activity should be visible through logging and monitoring.

### Testability

Security controls should be validated through deliberate allowed and denied traffic tests.

---

# 23. Current Implementation Status

The project is being built incrementally.

### Networking

* [x] VPC
* [x] Subnets
* [x] Internet Gateway
* [x] Public route table
* [x] NAT Gateway
* [x] Application route tables
* [x] Data route tables
* [ ] Management route configuration review

### Compute

* [x] Bastion/management instance
* [x] Private application instance
* [ ] Second application instance
* [ ] Application deployment validation

### Load Balancing

* [ ] Application Load Balancer
* [ ] Target group
* [ ] Health checks
* [ ] Multi-AZ application targets

### Database

* [ ] RDS PostgreSQL
* [ ] DB subnet group
* [ ] Private database connectivity
* [ ] Application-to-database testing

### Security

* [ ] Security Groups
* [ ] Network ACLs
* [ ] AWS WAF
* [ ] VPC Flow Logs
* [ ] CloudTrail
* [ ] EventBridge
* [ ] Lambda drift detection
* [ ] SNS alerts

### Monitoring

* [ ] CloudWatch dashboard
* [ ] ALB metrics
* [ ] EC2 metrics
* [ ] RDS metrics
* [ ] WAF metrics
* [ ] Flow Log investigation

### DNS

* [ ] Route 53 private hosted zone
* [ ] Internal application DNS

---

# 24. What This Project Demonstrates

Netwall demonstrates practical understanding of how AWS networking components interact rather than treating them as isolated services.

For example:

```text
VPC
 ↓
Subnet
 ↓
Route Table
 ↓
Security Group
 ↓
Network ACL
 ↓
EC2 ENI
 ↓
Application
```

For public application traffic:

```text
Internet
 ↓
WAF
 ↓
ALB
 ↓
Target Group
 ↓
Private EC2
```

For database traffic:

```text
Private EC2
 ↓
Route Table
 ↓
Security Group
 ↓
RDS
```

For outbound private traffic:

```text
Private EC2
 ↓
Route Table
 ↓
NAT Gateway
 ↓
Internet Gateway
 ↓
Internet
```

For security monitoring:

```text
Traffic
 ↓
VPC Flow Logs
 ↓
CloudWatch


AWS API Change
 ↓
CloudTrail
 ↓
EventBridge
 ↓
Lambda
 ↓
SNS
```

---

# 25. Lessons Learned

The main lesson from Netwall is that cloud networking is not about memorizing AWS services.

It is about understanding the **complete traffic path**.

When something fails, the question becomes:

> Where did the packet stop?

That means checking:

```text
Source
 ↓
ENI
 ↓
Subnet
 ↓
Route Table
 ↓
Security Group
 ↓
NACL
 ↓
Destination
```

and then checking the return path.

This approach makes it possible to troubleshoot connectivity systematically rather than changing security rules without understanding the cause.

---

# 26. Project Status

Netwall is an ongoing hands-on AWS networking and security laboratory.

The architecture is being implemented incrementally, tested through deliberate connectivity scenarios, and documented based on actual implementation rather than assumed production experience.

The primary objective is to develop strong practical understanding of:

**AWS Networking → Security → Monitoring → Troubleshooting → Controlled Change**

---

## Author

**Precious Israel**

Cloud / DevOps / Cloud Networking & Security

GitHub: `Precious000`
