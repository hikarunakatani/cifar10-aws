terraform {
  required_version = "~> 1.6.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.7.0"
    }
  }
  backend "s3" {
    bucket = "terraform-state-nakatani"
    region = "ap-northeast-1"
    key = "terraform.tfstate"
    encrypt = true
  }
}

