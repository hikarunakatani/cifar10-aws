# VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "${var.project_name}-vpc"
  }
}

resource "aws_route_table" "main" {
  vpc_id = aws_vpc.main.id
}

# Subnet
resource "aws_subnet" "private1a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = var.aws_az1
  tags = {
    Name = "${var.project_name}-subnet-private-${var.aws_az1}"
  }
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private1a.id
  route_table_id = aws_route_table.main.id
}

# S3 Endpoint
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.main.id]
  policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Sid = "Access-to-specific-bucket-only",
          Principal = "*",
          Action = [
            "s3:GetObject"
          ],
          Effect = "Allow"
          Resource = [
            "arn:aws:s3:::prod-${var.aws_region}-starport-layer-bucket/*",
            "arn:aws:s3:::cifar10-mlops-bucket/*"
          ]
          
        }
      ]
    })
}

# ECR Endpoint
resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id             = aws_vpc.main.id
  service_name       = "com.amazonaws.${var.aws_region}.ecr.dkr"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = [aws_subnet.private1a.id]
  security_group_ids = [aws_security_group.vpc_endpoint.id]
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id             = aws_vpc.main.id
  service_name       = "com.amazonaws.${var.aws_region}.ecr.api"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = [aws_subnet.private1a.id]
  security_group_ids = [aws_security_group.vpc_endpoint.id]
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "logs" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.ap-northeast-1.logs"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.private1a.id]
  security_group_ids  = [aws_security_group.vpc_endpoint.id]
  private_dns_enabled = true
}
