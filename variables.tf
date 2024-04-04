provider "aws" {
  region = "ap-northeast-1"
}

data "aws_caller_identity" "self" {}

output "account_id" {
  value = data.aws_caller_identity.self.account_id
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