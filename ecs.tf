# ECR repository
resource "aws_ecr_repository" "main" {
  name                 = "${var.project_name}-repository"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
}

# ECS cluster
resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-cluster"
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

# May delete later
# resource "aws_ecs_cluster_capacity_providers" "this" {
#   cluster_name       = aws_ecs_cluster.main.name
#   capacity_providers = ["FARGATE"]
#   default_capacity_provider_strategy {
#     capacity_provider = "FARGATE"
#   }
# }

resource "aws_iam_role" "ecs_task_exec" {
  name = "ecs_task_exec"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "ecs-tasks.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  ]
}

# Required to acces to ECR repository from VPC Endpoint
resource "aws_iam_policy" "s3_access_policy" {
  name = "s3-access-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "s3:GetObject",
        "s3:ListBucket"
      ]
      Resource = [
        "arn:aws:s3:::prod-${var.aws_region}-starport-layer-bucket/*"
      ]
    }]
  })
}

resource "aws_iam_role_policy_attachment" "s3_access_policy_attachment" {
  role       = aws_iam_role.ecs_task_exec.name
  policy_arn = aws_iam_policy.s3_access_policy.arn
}

# ECS Service
resource "aws_iam_role" "ecs_task_role" {
  name = "ecs_task_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "ecs-tasks.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })
  inline_policy {
    name = "allow_logs"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "logs:CreateLogStream",
            "logs:DescribeLogGroups",
            "logs:DescribeLogStreams",
            "logs:PutLogEvents",
          ],
          Resource = "*"
        }
      ]
    })
  }
}

# Task Definition
resource "aws_ecs_task_definition" "main" {
  family                   = "${var.project_name}-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "2048" # 2 vCPU
  memory                   = "8192" # 8GB RAM
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  execution_role_arn       = aws_iam_role.ecs_task_exec.arn

  container_definitions = jsonencode([
    {
      name      = "${var.project_name}-container"
      image     = "${aws_ecr_repository.main.repository_url}:latest"
      cpu       = 2048
      memory    = 4098
      essential = true
      portMappings = [
        {
          "containerPort" : 80,
          "hostPort" : 80
        }
      ],
      # mountPoints = [
      #   {
      #     "containerPath" : "/data",
      #     "readOnly" : false
      #   }
      # ],
      logConfiguration = {
        options = {
          "awslogs-region"        = "ap-northeast-1"
          "awslogs-group"         = "aws_cloudwatch_log_group.main.name"
          "awslogs-stream-prefix" = "ecs"
        }
        logDriver = "awslogs"
      }
    }
  ])
}

resource "aws_cloudwatch_log_group" "main" {
  name = "${var.project_name}-log-group"
}