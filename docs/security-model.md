# Netwall Security Model

## Network segmentation

Netwall separates:

1. Public resources
2. Application resources
3. Database resources
4. Management resources

This limits the blast radius of a compromised resource.

## Security Groups

Security Groups are used as stateful virtual firewalls.

The intended relationships are:

ALB SG
|
+--> App SG : TCP 8080

Management/EICE SG
|
+--> App SG : TCP 22

App SG
|
+--> Data SG : TCP 5432

## Database protection

The PostgreSQL database:

- uses private subnets
- is not publicly accessible
- only accepts application traffic on TCP 5432

## Application protection

The application instances:

- have no public IP addresses
- accept application traffic from the ALB
- accept administrative SSH traffic only through the controlled management path

## WAF

AWS WAF protects the public application entry point.

Example controls include:

- SQL injection protection
- cross-site scripting protection
- rate limiting

## Network visibility

VPC Flow Logs provide metadata about network traffic.

This allows administrators to investigate:

- rejected traffic
- unexpected connections
- unusual source addresses
- unexpected destination ports

## Security automation

Netwall uses Lambda automation for security operations such as:

- security-group drift detection
- flow-log analysis
- security reporting

## Zero-trust principle

Access is granted based on the identity and security context of the connection rather than assuming that traffic inside the VPC is automatically trusted.
