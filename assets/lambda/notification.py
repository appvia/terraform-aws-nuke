#!/usr/bin/env python3
"""
This Lambda function is triggered by the completion of the ECS task
that runs the AWS Nuke container. It retrieves the logs from the
CloudWatch log group and sends a notification via SNS if any resources
are going to be deleted.
"""

import os
import logging

import boto3

# Initialize AWS clients
logs_client = boto3.client('logs')
sns_client = boto3.client('sns')

# Environment variables for configuration
LOG_GROUP_NAME = os.getenv('LOG_GROUP_NAME')
SNS_TOPIC_ARN = os.getenv('SNS_TOPIC_ARN')
DEBUG = os.getenv('DEBUG', 'false').lower() == 'true'

# Set up logging
logger = logging.getLogger()
logger.setLevel(logging.DEBUG if DEBUG else logging.INFO)


def retrieve_cloudwatch_logs():
    """
    We retrieve the logs from cloudwatch, parsing line by line for
    'would remove' and produce a summary of the logs to send.
    """

    logging.debug("Retrieving %s cloudwatch log group", LOG_GROUP_NAME)

    matching_lines = []
    # Get the list of log streams (assuming each ECS task has
    # its own log stream)
    streams = logs_client.describe_log_streams(
        logGroupName=LOG_GROUP_NAME,
        orderBy='LastEventTime',
        descending=True,
        limit=1
    )['logStreams']
    for stream in streams:
        log_stream_name = stream['logStreamName']
        # Get log events for each log stream
        events = logs_client.get_log_events(
            logGroupName=LOG_GROUP_NAME,
            logStreamName=log_stream_name,
            startFromHead=False
        )['events']
        # Check each event for the "would remove" text
        for event in events:
            message = event['message']
            if 'would remove' in message:
                matching_lines.append(message)

    return matching_lines


def lambda_handler(event, context):
    """
    The main entry point of the Lambda function. This method is
    called on the completion of the ECS task. We query the logs
    within cloudwatch, parse and send a notification via SNS
    """

    matching_lines = retrieve_cloudwatch_logs()
    message = {
        "Number of Resources ", len(matching_lines),
    }
    logging.debug("Finished processing event, %s", message)

    if matching_lines and len(SNS_TOPIC_ARN) > 0:
        sns_client.publish(
            TopicArn=SNS_TOPIC_ARN,
            Message=message,
            Subject="AWS Nuke - Resource Deletion Notification"
        )


# If not being called from the lambda_handler, but via the CLI,
# we need to call the lambda_handler
if __name__ == '__main__':
    lambda_handler(None, None)
