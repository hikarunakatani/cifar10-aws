# VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "${var.project_name}-vpc"
  }
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

# S3 Endpoint
resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.${var.aws_region}.s3"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "*"
        Effect    = "Allow"
        Resource  = "*"
        Principal = "*"
      }
    ]
  })
}

# Route Table
resource "aws_route_table" "main" {
  vpc_id = aws_vpc.main.id
  #route {
    #cidr_block      = "10.0.1.0/24"
    # vpc_endpoint_id = aws_vpc_endpoint.s3.id
    #gateway_id      = "local"
    # depends_on = [aws_vpc_endpoint.s3]
  #}
}

# Route Table Association
resource "aws_vpc_endpoint_route_table_association" "main" {
  vpc_endpoint_id = aws_vpc_endpoint.s3.id
  route_table_id  = aws_route_table.main.id
}

# ECR Endpoint
resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id             = aws_vpc.main.id
  service_name       = "com.amazonaws.${var.aws_region}.ecr.dkr"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = [aws_subnet.private1a.id]
  security_group_ids = [aws_security_group.vpc_endpoint.id]
}

resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id             = aws_vpc.main.id
  service_name       = "com.amazonaws.${var.aws_region}.ecr.api"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = [aws_subnet.private1a.id]
  security_group_ids = [aws_security_group.vpc_endpoint.id]
}

