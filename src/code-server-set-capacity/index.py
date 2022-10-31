import boto3
import os
import json
import logging
from jsonschema import validate 
from typing import Dict, Any
import base64

def lambda_handler(event, context):
    asg_name = os.environ['ASG_NAME']
    region = os.environ['AWS_REGION']
    logger = logging.getLogger()
    logger.setLevel(logging.INFO)
    logger.info(event)

    json_body = None

    try:
        json_body = validate_event_schema(base64.b64decode(event['body']))
    except Exception as e:
        logger.error('Failed to validate input')
        logger.error(str(e))
        return {
                'statusCode': 500,
                'body': 'Failed to validate input. Please consult the documentation for the appropriate format.'
            }

    client = boto3.client('autoscaling', region_name=region)

    desired_capacity = json_body['DesiredCapacity']
    if not 0 <= desired_capacity <= 1:
        logger.error(f'Invalid capacity requested: {desired_capacity}')
        return {
                'statusCode': 400,
                'body': f'Invalid capacity requested: {desired_capacity}. Only 1 and 0 are supported.'
            }
    response = client.set_desired_capacity(
        AutoScalingGroupName=asg_name,
        DesiredCapacity=desired_capacity,
        HonorCooldown=False
    )
    logger.info(f'Set desired instance count to {desired_capacity} for {asg_name}')
    return({'status':'success'})


def validate_event_schema(event_body: str) -> Dict[str, int]:
    schema = {
        "type" : "object",
        "properties" : {
            "DesiredCapacity" : {"type" : "number"},
        },
    }
    json_event = json.loads(event_body)
    validate(instance=json_event, schema=schema)
    return(json_event)
