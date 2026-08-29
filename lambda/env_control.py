import json
import logging
import os
from typing import List

import boto3
from botocore.exceptions import ClientError

logger = logging.getLogger()
logger.setLevel(logging.INFO)

TARGET_ROLE_ARN = os.environ["TARGET_ROLE_ARN"]
TARGET_REGION = os.environ.get("TARGET_REGION", "ap-northeast-1")
TAG_KEY = os.environ.get("TAG_KEY", "EnvControl")
TAG_VALUE = os.environ.get("TAG_VALUE", "True")


def assume_target_role():
    """Assume EnvControlRole in the target AWS account."""
    sts = boto3.client("sts")

    response = sts.assume_role(
        RoleArn=TARGET_ROLE_ARN,
        RoleSessionName="EnvControlLambdaSession",
    )

    credentials = response["Credentials"]

    return boto3.client(
        "ec2",
        region_name=TARGET_REGION,
        aws_access_key_id=credentials["AccessKeyId"],
        aws_secret_access_key=credentials["SecretAccessKey"],
        aws_session_token=credentials["SessionToken"],
    )


def get_instance_ids(ec2, action: str) -> List[str]:
    """
    Return EC2 instance IDs that:
      1. have EnvControl=True
      2. are in the correct state for the requested action
    """
    state = "stopped" if action == "start" else "running"

    paginator = ec2.get_paginator("describe_instances")

    instance_ids = []

    for page in paginator.paginate(
        Filters=[
            {
                "Name": f"tag:{TAG_KEY}",
                "Values": [TAG_VALUE],
            },
            {
                "Name": "instance-state-name",
                "Values": [state],
            },
        ]
    ):
        for reservation in page.get("Reservations", []):
            for instance in reservation.get("Instances", []):
                instance_ids.append(instance["InstanceId"])

    return instance_ids


def lambda_handler(event, context):
    """Start or stop EC2 instances tagged EnvControl=True."""
    action = str(event.get("action", "")).lower()

    if action not in {"start", "stop"}:
        return {
            "statusCode": 400,
            "body": json.dumps(
                {
                    "message": "Invalid action. Use 'start' or 'stop'."
                }
            ),
        }

    try:
        ec2 = assume_target_role()
        instance_ids = get_instance_ids(ec2, action)

        if not instance_ids:
            logger.info(
                "No matching instances. action=%s tag=%s:%s",
                action,
                TAG_KEY,
                TAG_VALUE,
            )

            return {
                "statusCode": 200,
                "body": json.dumps(
                    {
                        "action": action,
                        "instances": [],
                        "message": "No matching instances found.",
                    }
                ),
            }

        if action == "start":
            ec2.start_instances(InstanceIds=instance_ids)
        else:
            ec2.stop_instances(InstanceIds=instance_ids)

        logger.info(
            "EC2 action submitted. action=%s instances=%s",
            action,
            instance_ids,
        )

        return {
            "statusCode": 200,
            "body": json.dumps(
                {
                    "action": action,
                    "instances": instance_ids,
                    "message": f"{action.title()} request submitted.",
                }
            ),
        }

    except ClientError:
        logger.exception("AWS API call failed.")
        raise
