import json
import boto3

ec2 = boto3.client("ec2")
rds = boto3.client("rds")
elbv2 = boto3.client("elbv2")


def lambda_handler(event, context):

    vpc = ec2.describe_vpcs(
        Filters=[
            {
                "Name": "tag:Name",
                "Values": ["netwall-vpc"]
            }
        ]
    )

    result = {
        "project": "Netwall",
        "vpc": None,
        "alb": None,
        "database": None
    }

    if vpc["Vpcs"]:
        result["vpc"] = {
            "id": vpc["Vpcs"][0]["VpcId"],
            "cidr": vpc["Vpcs"][0]["CidrBlock"]
        }

    try:
        alb = elbv2.describe_load_balancers(
            Names=["netwall-alb"]
        )

        if alb["LoadBalancers"]:
            result["alb"] = {
                "name": alb["LoadBalancers"][0]["LoadBalancerName"],
                "dns": alb["LoadBalancers"][0]["DNSName"],
                "state": alb["LoadBalancers"][0]["State"]["Code"]
            }
    except Exception as error:
        result["alb"] = {
            "error": str(error)
        }

    try:
        database = rds.describe_db_instances(
            DBInstanceIdentifier="netwall-data"
        )

        if database["DBInstances"]:
            db = database["DBInstances"][0]

            result["database"] = {
                "identifier": db["DBInstanceIdentifier"],
                "engine": db["Engine"],
                "status": db["DBInstanceStatus"],
                "publicly_accessible": db["PubliclyAccessible"]
            }

    except Exception as error:
        result["database"] = {
            "error": str(error)
        }

    return {
        "statusCode": 200,
        "headers": {
            "Content-Type": "application/json"
        },
        "body": json.dumps(result)
    }
