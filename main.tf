terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.8"
    }
  }
}

variable "ami_id" {
  type    = string
  default = "amazon"
}

variable "instance_type" {
  type    = string
  default = "t3.large"
}

variable "key_name" {
  type    = string
  default = "pyee"
}

provider "aws" {
  region = "us-west-2"
}

data "aws_ssm_parameter" "amazon" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

data "aws_ssm_parameter" "vpc_id" {
  name = "/main/vpc/id"
}

data "aws_ssm_parameter" "ssh_sg_id" {
  name = "/main/core-sgs/CorpVPNSourcesSSH/id"
}

data "aws_ssm_parameter" "protected_subnet_ids" {
  name = "/main/vpc/subnets/protected/ids"
}

data "aws_ssm_parameter" "route53_zone_id" {
  name = "/main/route53/zone/id"
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
  ami                  = var.ami_id == "amazon" ? data.aws_ssm_parameter.amazon.value : var.ami_id
  instance_type        = var.instance_type
  key_name             = var.key_name
  root_block_device {
    delete_on_termination = true
    volume_size           = 50
    volume_type           = "gp2"
  }
  spot_type            = "one-time"
  subnet_id            = element(split(",", data.aws_ssm_parameter.protected_subnet_ids.value), 1)
  vpc_security_group_ids = [
    data.aws_ssm_parameter.ssh_sg_id.value,
    aws_security_group.allow_all_outbound_sg.id,
  ]
  wait_for_fulfillment = "true"

  tags = var.resource_tags
}

resource "aws_route53_record" "record" {
  zone_id = data.aws_ssm_parameter.route53_zone_id.value
  name    = "pyee-ec2"
  type    = "A"
  ttl     = 300
  records = [aws_spot_instance_request.my_instance.private_ip]
}

output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_spot_instance_request.my_instance.spot_instance_id
}

output "instance_private_ip" {
  description = "Private IP address of the EC2 instance"
  value       = aws_spot_instance_request.my_instance.private_ip
}

output "instance_route53_fqdn" {
  description = "FQDN of the EC2 instance"
  value       = aws_route53_record.record.fqdn
}
