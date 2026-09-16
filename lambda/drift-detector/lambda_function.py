import os
import boto3

ec2 = boto3.client("ec2")

PROTECTED_SG_ID = os.environ["PROTECTED_SG_ID"]
PROTECTED_PORT = int(os.environ.get("PROTECTED_PORT", "22"))


def lambda_handler(event, context):

    removed = []

    response = ec2.describe_security_groups(
        GroupIds=[PROTECTED_SG_ID]
    )

    sg = response["SecurityGroups"][0]

    for permission in sg.get("IpPermissions", []):

        if permission.get("IpProtocol") != "tcp":
            continue

        if permission.get("FromPort") != PROTECTED_PORT:
            continue

        if permission.get("ToPort") != PROTECTED_PORT:
            continue

        for ip_range in permission.get("IpRanges", []):

            if ip_range.get("CidrIp") == "0.0.0.0/0":

                ec2.revoke_security_group_ingress(
                    GroupId=PROTECTED_SG_ID,
                    IpPermissions=[{
                        "IpProtocol": "tcp",
                        "FromPort": PROTECTED_PORT,
                        "ToPort": PROTECTED_PORT,
                        "IpRanges": [
                            {
                                "CidrIp": "0.0.0.0/0"
                            }
                        ]
                    }]
                )

                removed.append(
                    f"Removed TCP {PROTECTED_PORT} from 0.0.0.0/0"
                )

    return {
        "statusCode": 200,
        "removed": removed,
        "message": "Security group drift check completed"
    }
