import boto3
import os
import json
import logging
from jsonschema import validate 
from typing import Dict, Any

def lambda_handler(event, context):
    asg_name = os.environ['ASG_NAME']
    region = os.environ['AWS_REGION']
    logger = logging.getLogger()
    logger.setLevel(logging.INFO)

    # try:
    validate_event_schema(event)
    # except jsonschema.exceptions.ValidationError as e:
    #     raise LambdaException({
    #         "isError": True,
    #         "type":  e.__class__.__name__,
    #         "message": str(e)
    #     })
    # except json.decoder.JSONDecodeError as e:
    #     raise LambdaException({
    #         "isError": True,
    #         "type":  e.__class__.__name__,
    #         "message": "Failed to parse input. Please refer to the documentation for the appropriate input format."
    #     })

    client = boto3.client('autoscaling', region_name=region)

    desired_capacity = event['desired_capacity']
    response = client.set_desired_capacity(
        AutoScalingGroupName=asg_name,
        DesiredCapacity=desired_capacity,
        HonorCooldown=False
    )
    logger.info(f'Set desired instance count to {desired_capacity} for {asg_name}')
    return({'status':'success'})


def validate_event_schema(event: Dict[Any, Any]) -> Dict[str, int]:
    schema = {
        "type" : "object",
        "properties" : {
            "desired_capacity" : {"type" : "number"},
        },
    }
    validate(instance=event, schema=schema)
