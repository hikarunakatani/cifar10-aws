# provider "aws" {
#   region = "us-west-2"
# }

# # Please note that the cost of running this instance will depend on the 
# # current pricing in the us-west-2 region. As of March 2022, the On-Demand price for 
# # a p2.xlarge instance in the us-west-2 region is approximately $0.90 per hour.

# data "aws_ami" "ubuntu" {
#   most_recent = true
#   filter {
#     name   = "name"
#     values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
#   }
#   filter {
#     name   = "virtualization-type"
#     values = ["hvm"]
#   }
#   owners = ["099720109477"] # Canonical
# }

# resource "aws_instance" "gpu_instance" {
#   ami           = data.aws_ami.ubuntu.id
#   instance_type = "p2.xlarge"

#   tags = {
#     Name = "GPU Instance"
#   }
# }