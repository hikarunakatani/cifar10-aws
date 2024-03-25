resource "aws_cloudwatch_event_rule" "ecr_push_rule" {
  name = "${var.project_name}-run-ecs-task"
  event_pattern = jsonencode([
    {
      source      = "aws.ecr"
      detail-type = "ECR Image Action"
      detail = {
        "action-type" : ["PUSH"]
    } }
  ])
}

resource "aws_cloudwatch_event_target" "ecr_push_target" {
  rule      = aws_cloudwatch_event_rule.ecr_push_rule.name
  target_id = "run-index-py-function"
  arn       = aws_lambda_function.index_py.arn
}


