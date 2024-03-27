provider "aws" {
  region = "ap-northeast-1"
}

variable "aws_region" {
  type        = string
  default     = "ap-northeast-1"
  description = "Region to deploy resources."
}

variable "aws_az1" {
  type        = string
  default     = "ap-northeast-1a"
  description = "Availability zone to deploy resources."
}

variable "project_name" {
  type        = string
  default     = "cifar10-mlops"
  description = "Project name."
}

# variable "ecr_repository_url" {
#   type        = string
#   description = "URL of ECR repository."
# }

# variable "image_tag" {
#   type        = string
#   description = "The tag of the Docker image"
# }