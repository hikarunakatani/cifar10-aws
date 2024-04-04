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

resource "aws_ecs_cluster_capacity_providers" "this" {
  cluster_name       = aws_ecs_cluster.main.name
  capacity_providers = ["FARGATE"]
  default_capacity_provider_strategy {
    capacity_provider = "FARGATE"
  }
}

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

# ECS Service
resource "aws_cloudwatch_log_group" "main" {
  name = "${var.project_name}-log-group"
}

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
resource "aws_ecs_task_definition" "service" {
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

# ECS Service
resource "aws_ecs_service" "main" {
  capacity_provider_strategy {
    capacity_provider = "FARGATE"
    base              = 0
    weight            = 100
  }
  cluster                            = aws_ecs_cluster.main.id
  platform_version                   = "LATEST"
  task_definition                    = aws_ecs_task_definition.service.id
  name                               = "${var.project_name}-service"
  desired_count                      = 1
  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200
  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }
  network_configuration {
    subnets = [
      "${aws_subnet.private1a.id}",
    ]
    security_groups = [
      "${aws_security_group.ecs.id}"
    ]
    assign_public_ip = true
  }
}