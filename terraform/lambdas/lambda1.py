import json
import boto3

dynamodb = boto3.client("dynamodb")

def lambda_handler(event, context):
    data = json.loads(event["body"])
    string = data["string"]
    character = data["character"]

    occurrences = string.count(character)

    response = dynamodb.put_item(
        TableName="OccurrencesTable",
        Item={
            "ID": {"S": event["requestContext"]["requestId"]},
            "String": {"S": string},
            "Character": {"S": character},
            "Occurrences": {"N": str(occurrences)},
        },
    )

    return {
        "statusCode": 200,
        "body": json.dumps({"id": event["requestContext"]["requestId"]}),
    }
