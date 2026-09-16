import os
import time
import boto3

logs = boto3.client("logs")

LOG_GROUP = os.environ.get(
    "LOG_GROUP",
    "/netwall/vpc-flow-logs"
)


def lambda_handler(event, context):

    query = """
    fields @timestamp, srcAddr, dstAddr, srcPort, dstPort, action
    | filter action = "REJECT"
    | sort @timestamp desc
    | limit 20
    """

    start_time = int(time.time() - 900)
    end_time = int(time.time())

    response = logs.start_query(
        logGroupName=LOG_GROUP,
        startTime=start_time,
        endTime=end_time,
        queryString=query
    )

    query_id = response["queryId"]

    return {
        "statusCode": 200,
        "queryId": query_id,
        "message": "Flow-log analysis query started"
    }
