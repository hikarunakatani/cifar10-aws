import boto3

def invoke_ecs_task():
    # Function to invoke ECS task
    ecs_client = boto3.client('ecs')

    # ECS task definition

    name_prefix = 'cifar10-mlops'
    task_definition = name_prefix + '-task-definition'  
    cluster = name_prefix + '-cluster'  
    subnet = name_prefix + '-subnet-private-ap-northeast-1'  
    security_group = name_prefix + 'ecs-securitygroup'

    # Invoke ECS task
    response = ecs_client.run_task(
        cluster=cluster,
        taskDefinition=task_definition,
        launchType='FARGATE',
        networkConfiguration={
            'awsvpcConfiguration': {
                'subnets': [
                    subnet
                ],
                'securityGroups': [
                    security_group
                ],
                'assignPublicIp': 'ENABLED'
            }
        }
    )

    # Display task info
    print(response)
