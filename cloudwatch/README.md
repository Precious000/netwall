# Netwall CloudWatch Monitoring

Netwall uses CloudWatch for centralized monitoring of security and network activity.

## Components

### VPC Flow Logs

VPC Flow Logs capture network traffic metadata from the Netwall VPC.

Destination:

- CloudWatch Logs
- Log group: `/netwall/vpc-flow-logs`

The flow logs record accepted and rejected traffic.

### Security Monitoring

CloudWatch provides the logging layer used by Netwall security automation.

The intended flow is:

VPC
|
+-- VPC Flow Logs
        |
        v
CloudWatch Logs
        |
        +-- Flow Analyzer Lambda
        |
        +-- Security investigation

## Important distinction

VPC Flow Logs contain network metadata. They do not capture packet payloads.

Typical information includes:

- source IP
- destination IP
- source port
- destination port
- protocol
- action
- bytes
- packets
