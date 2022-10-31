import boto3
import os
import logging

def lambda_handler(event, context):
    asg_name = os.environ['ASG_NAME']
    region = os.environ['AWS_REGION']
    logger = logging.getLogger()
    logger.setLevel(logging.INFO)


    client = boto3.client('autoscaling', region_name=region)
    logger.debug(f'Looking up status of code-server ASG')

    response = client.describe_auto_scaling_groups(
        AutoScalingGroupNames=[
            asg_name,
        ]
    )

    if 'AutoScalingGroups' in response:
        response = response['AutoScalingGroups']
        if len(response) == 1:
            logger.debug('Found code-server ASG')
            response = {
                'AutoScalingGroupName': response[0]['AutoScalingGroupName'], 
                'DesiredCapacity': response[0]['DesiredCapacity'],
                'MinSize': response[0]['MinSize'],
                'MaxSize': response[0]['MaxSize']
                }
            logger.info(response)
            return(response)
        else:
            logger.error('No ASG in response')
            logger.error(response)
            return({
                'statusCode': 404,
                'body': 'No ASG in response'
            })
    else:
        logger.error('Bad response')
        logger.error(response)
        return({
                'statusCode': 500,
                'body': 'Bad response'
            })
