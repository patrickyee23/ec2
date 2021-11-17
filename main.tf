terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = "us-west-2"
}

data "aws_ssm_parameter" "amazon_linux_ami" {
  name = "/aws/service/ami-amazon-linux-latest/amzn-ami-hvm-x86_64-gp2"
}

data "aws_ssm_parameter" "vpc_id" {
  name = "/main/vpc/id"
}

data "aws_ssm_parameter" "ssh_sg_id" {
  name = "/main/core-sgs/CorpAuthenticatedSourcesSSH/id"
}

data "aws_ssm_parameter" "protected_subnet_ids" {
  name = "/main/vpc/subnets/protected/ids"
}

variable "resource_tags" {
  default = {
    AccountingCategory = "Engineering"
    Name               = "pyee"
    Service            = "coregen"
    Purpose            = "playground"
  }
}

resource "aws_security_group" "allow_all_outbound_sg" {
  name        = "allow_all_outbound_sg"
  description = "Allow all outbound traffic"
  vpc_id      = data.aws_ssm_parameter.vpc_id.value

  egress {
    description      = "all traffic"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = var.resource_tags
}

resource "aws_spot_instance_request" "my_instance" {
  ami           = data.aws_ssm_parameter.amazon_linux_ami.value
  instance_type = "t3.large"
  key_name      = "pyee"
  spot_price    = "0.0832"
  spot_type     = "one-time"
  subnet_id     = element(split(",", data.aws_ssm_parameter.protected_subnet_ids.value), 1)
  vpc_security_group_ids = [
    data.aws_ssm_parameter.ssh_sg_id.value,
    aws_security_group.allow_all_outbound_sg.id,
  ]
  wait_for_fulfillment = "true"

  tags = var.resource_tags
}

output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_spot_instance_request.my_instance.spot_instance_id
}

output "instance_private_ip" {
  description = "Private IP address of the EC2 instance"
  value       = aws_spot_instance_request.my_instance.private_ip
}
