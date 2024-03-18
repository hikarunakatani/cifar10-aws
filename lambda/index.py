from invoke_task import invoke_ecs_task

def lambda_handler(event, context):
    # Handler of a Lambda funciton
    print("Lambda function triggered")

    # Invoke ECS task
    invoke_ecs_task()