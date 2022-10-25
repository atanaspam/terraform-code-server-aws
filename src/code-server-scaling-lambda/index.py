import boto3
import os

def lambda_handler(event, context):
    client = boto3.client('autoscaling')
    print("Hello from app1!")
    print(event)
    asg_name = os.environ['ASG_NAME']

    response = client.describe_auto_scaling_groups(
        AutoScalingGroupNames=[
            asg_name,
        ]
    )
    if len(response) == 0:
        print(response[0]['AutoScalingGroupName'])
        print(response[0]['DesiredCapacity'])
        print(response[0]['MinSize'])
        print(response[0]['MaxSize'])

    return event
