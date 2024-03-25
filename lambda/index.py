import boto3
import json
import logging
import os
import sys

logger = logging.getLogger()
for h in logger.handlers:
    logger.removeHandler(h)
h = logging.StreamHandler(sys.stdout)
FORMAT = "%(levelname)s [%(funcName)s] %(message)s"
h.setFormatter(logging.Formatter(FORMAT))
logger.addHandler(h)
logger.setLevel(logging.INFO)

ecs = boto3.client("ecs")


def run_ecs_task(cluster, task_definition, subnets, security_groups, payload):
    try:
        response = ecs.run_task(
            cluster=cluster,
            taskDefinition=task_definition,
            launchType="FARGATE",
            networkConfiguration={
                "awsvpcConfiguration": {
                    "subnets": subnets.split(","),
                    "securityGroups": security_groups.split(","),
                    "assignPublicIp": "ENABLED",
                }
            },
            overrides={
                "containerOverrides": [
                    {
                        "name": "sample-ecr-dev",
                        "command": ["python", "sample.py"],
                        "memory": 128,
                        "environment": [
                            {"name": "PARAMS", "value": json.dumps(payload)}
                        ],
                    }
                ]
            },
        )
        logger.info(f"Response: {response}")
        failures = response.get("failures", [])
        if failures:
            logger.error(f"Task failures: {failures}")
    except Exception as e:
        logger.error(f"Error running ECS task: {e}")


def lambda_handler(event, context):
    try:
        ECS_CLUSTER = os.environ["ECS_CLUSTER"]
        TASK_DEFINITION_ARN = os.environ["TASK_DEFINITION_ARN"]
        AWSVPC_CONF_SUBNETS = os.environ["AWSVPC_CONF_SUBNETS"]
        AWSVPC_CONF_SECURITY_GROUPS = os.environ["AWSVPC_CONF_SECURITY_GROUPS"]

        for record in event["Records"]:
            payload = json.loads(record["body"])
            logger.info(f"ECS_CLUSTER: {ECS_CLUSTER}")
            logger.info(f"TASK_DEFINITION_ARN: {TASK_DEFINITION_ARN}")
            run_ecs_task(
                ECS_CLUSTER,
                TASK_DEFINITION_ARN,
                AWSVPC_CONF_SUBNETS,
                AWSVPC_CONF_SECURITY_GROUPS,
                payload,
            )
    except Exception as e:
        logger.error(f"Lambda handler error: {e}")
