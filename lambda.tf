# Allow assume role
resource "aws_iam_role" "lambda_execution_role" {
  name = "${var.project_name}-lambda-execution-role"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [{
      "Effect" : "Allow",
      "Principal" : {
        "Service" : "lambda.amazonaws.com"
      },
      "Action" : "sts:AssumeRole"
    }]
  })
  inline_policy {
    name = "lambda_execution_policy"
    policy = jsonencode({
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Action" : [
            "ecr:GetAuthorizationToken",
            "ecr:BatchCheckLayerAvailability",
            "ecr:GetDownloadUrlForLayer",
            "ecs:RunTask",
            "ecr:BatchGetImage",
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents",
            "iam:PassRole"
          ],
          "Resource" : "*"
        }
      ]
    })
  }
}

# Lambda source 
data "archive_file" "lambda" {
  type        = "zip"
  source_file = "./lambda/invoke_task.py"
  output_path = "lambda_function.zip"
}

# Lambda function
resource "aws_lambda_function" "invoke_task" {
  # If the file is not in the current working directory you will need to include a
  # path.module in the filename.
  filename         = "lambda_function.zip"
  function_name    = "${var.project_name}-invoke-task"
  role             = aws_iam_role.lambda_execution_role.arn
  handler          = "invoke_task.lambda_handler"
  source_code_hash = data.archive_file.lambda.output_base64sha256
  runtime          = "python3.9"
  environment {
    variables = {
      ECS_CLUSTER                 = aws_ecs_cluster.main.name
      TASK_DEFINITION_ARN         = aws_ecs_task_definition.main.arn
      AWSVPC_CONF_SUBNETS         = "${aws_subnet.private1a.id}"
      AWSVPC_CONF_SECURITY_GROUPS = "${aws_security_group.ecs.id}"
    }
  }
}

# Allow EventBridge operations
resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.invoke_task.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.ecr_push_rule.arn
}