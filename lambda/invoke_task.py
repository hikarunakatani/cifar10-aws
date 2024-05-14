import json
import logging
import os
import sys
import boto3

# Setting up logging
logger = logging.getLogger()
for h in logger.handlers:
    logger.removeHandler(h)
h = logging.StreamHandler(sys.stdout)
FORMAT = "%(levelname)s [%(funcName)s] %(message)s"
h.setFormatter(logging.Formatter(FORMAT))
logger.addHandler(h)
logger.setLevel(logging.INFO)

ecs = boto3.client("ecs")


def run_ecs_task(cluster, task_definition, subnets, security_groups):
    """
    Function to run an ECS task.

    Parameters:
    cluster (str): The name of the ECS cluster.
    task_definition (str): The ARN of the task definition.
    subnets (str): The subnets for the task.
    security_groups (str): The security groups for the task.

    Returns:
    None
    """
    try:
        response = ecs.run_task(
            cluster=cluster,
            taskDefinition=task_definition,
            launchType="FARGATE",
            count=1,
            networkConfiguration={
                "awsvpcConfiguration": {
                    "subnets": subnets.split(","),
                    "securityGroups": security_groups.split(","),
                    "assignPublicIp": "ENABLED",
                }
            },
        )
        logger.info(f"Response: {response}")
        failures = response.get("failures", [])
        if failures:
            logger.error(f"Task failures: {failures}")
    except Exception as e:
        logger.error(f"Error running ECS task: {e}")


def lambda_handler(event, context):
    """
    AWS Lambda function handler.

    Parameters:
    event (dict): The event data passed by AWS Lambda service.
    context (LambdaContext): The context data passed by AWS Lambda service.

    Returns:
    None
    """
    try:
        # Get configuration from environmental variables
        ECS_CLUSTER = os.environ["ECS_CLUSTER"]
        TASK_DEFINITION_ARN = os.environ["TASK_DEFINITION_ARN"]
        AWSVPC_CONF_SUBNETS = os.environ["AWSVPC_CONF_SUBNETS"]
        AWSVPC_CONF_SECURITY_GROUPS = os.environ["AWSVPC_CONF_SECURITY_GROUPS"]

        logger.info(f"ECS_CLUSTER: {ECS_CLUSTER}")
        logger.info(f"TASK_DEFINITION_ARN: {TASK_DEFINITION_ARN}")
        run_ecs_task(
            ECS_CLUSTER,
            TASK_DEFINITION_ARN,
            AWSVPC_CONF_SUBNETS,
            AWSVPC_CONF_SECURITY_GROUPS,
        )
    except Exception as e:
        logger.error(f"An error occured while running ECS task: {e}")
