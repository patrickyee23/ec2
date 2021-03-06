terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

variable "type" {
  type    = string
  default = "amazon"
}

variable "instance_type" {
  type    = string
  default = "t3.large"
}

variable "spot_price" {
  type    = number
  default = 0.0832
}

variable "key_name" {
  type    = string
  default = "pyee"
}

provider "aws" {
  region = "us-west-2"
}

data "aws_ssm_parameter" "amazon" {
  name = "/aws/service/ami-amazon-linux-latest/amzn-ami-hvm-x86_64-gp2"
}

data "aws_ssm_parameter" "docker" {
  name = "/app/latest-ami/docker-runtime-ami/master"
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

resource "aws_iam_instance_profile" "profile" {
  role = aws_iam_role.role.name
}

resource "aws_iam_role" "role" {
  path = "/"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": "allowassume"
        }
    ]
}
EOF
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
  ami                  = var.type == "amazon" ? data.aws_ssm_parameter.amazon.value : data.aws_ssm_parameter.docker.value
  instance_type        = var.instance_type
  key_name             = var.key_name
  iam_instance_profile = aws_iam_instance_profile.profile.id
  spot_price           = var.spot_price
  spot_type            = "one-time"
  subnet_id            = element(split(",", data.aws_ssm_parameter.protected_subnet_ids.value), 1)
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
