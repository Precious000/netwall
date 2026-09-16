import boto3
import os
from datetime import datetime, timezone

ec2 = boto3.client("ec2")
rds = boto3.client("rds")
elbv2 = boto3.client("elbv2")

REGION = os.environ.get("AWS_REGION", "us-east-1")


def lambda_handler(event, context):

    report = {
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "region": REGION,
        "vpc": {},
        "alb": {},
        "rds": {}
    }

    vpcs = ec2.describe_vpcs(
        Filters=[
            {
                "Name": "tag:Name",
                "Values": ["netwall-vpc"]
            }
        ]
    )

    if vpcs["Vpcs"]:
        vpc = vpcs["Vpcs"][0]

        report["vpc"] = {
            "id": vpc["VpcId"],
            "cidr": vpc["CidrBlock"],
            "state": vpc["State"]
        }

    alb = elbv2.describe_load_balancers(
        Names=["netwall-alb"]
    )

    if alb["LoadBalancers"]:
        load_balancer = alb["LoadBalancers"][0]

        report["alb"] = {
            "name": load_balancer["LoadBalancerName"],
            "dns": load_balancer["DNSName"],
            "state": load_balancer["State"]["Code"]
        }

    db = rds.describe_db_instances(
        DBInstanceIdentifier="netwall-data"
    )

    if db["DBInstances"]:
        database = db["DBInstances"][0]

        report["rds"] = {
            "identifier": database["DBInstanceIdentifier"],
            "engine": database["Engine"],
            "status": database["DBInstanceStatus"],
            "publicly_accessible": database["PubliclyAccessible"]
        }

    print(report)

    return report
