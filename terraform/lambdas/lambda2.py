import json
import boto3

dynamodb = boto3.client("dynamodb")

def lambda_handler(event, context):
    unique_id = event["queryStringParameters"]["id"]

    response = dynamodb.get_item(
        TableName="OccurrencesTable", Key={"ID": {"S": unique_id}}
    )

    item = response.get("Item", {})
    result = {
        "string": item.get("String", {}).get("S", ""),
        "character": item.get("Character", {}).get("S", ""),
        "occurrences": int(item.get("Occurrences", {}).get("N", "0")),
    }

    return {
        "statusCode": 200,
        "body": json.dumps(result),
        "headers": {"Content-Type": "application/json"},
    }
