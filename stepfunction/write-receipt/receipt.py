import boto3
import json
import os
from datetime import datetime, timezone

s3 = boto3.client("s3")
bucket = os.environ["OUTPUT_BUCKET"]

def lambda_handler(event, context):
    order_id = event["orderId"]
    key = f"receipts/{order_id}.json"

    receipt = {
        "orderId": order_id,
        "customerEmail": event["customerEmail"],
        "amount": event["amount"],
        "createdAt": datetime.now(timezone.utc).isoformat(),
        "stepFunctionExecution": event["executionId"]
    }

    s3.put_object(
        Bucket=bucket,
        Key=key,
        Body=json.dumps(receipt, indent=2),
        ContentType="application/json"
    )

    return {
        "bucket": bucket,
        "key": key,
        "uri": f"s3://{bucket}/{key}"
    }