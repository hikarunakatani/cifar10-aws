# Security group for ECS task
resource "aws_security_group" "ecs" {
  vpc_id      = aws_vpc.main.id
  name        = "${var.project_name}-ecs-securitygroup"
  description = "Security group for training task"

  egress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
}
}

# Security group for VPC Endpoint
resource "aws_security_group" "vpc_endpoint" {
  vpc_id      = aws_vpc.main.id
  name        = "${var.project_name}-vpc-endpoint-securitygroup"
  description = "Security group for VPC Endpoint"

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    cidr_blocks = [aws_subnet.private1a.cidr_block]
  }
}