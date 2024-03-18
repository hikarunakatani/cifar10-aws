resource "aws_security_group" "ecs" {
  vpc_id      = aws_vpc.main.id
  name        = "${var.project_name}-ecs-securitygroup"
  description = "Security group for training task"
}

resource "aws_security_group" "vpc_endpoint" {
  vpc_id      = aws_vpc.main.id
  name        = "${var.project_name}-vpc-endpoint-securitygroup"
  description = "Security group for VPC Endpoint"

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }
}