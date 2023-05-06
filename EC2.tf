terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "us-east-1"
  profile = "teraform-builder"
}

resource "aws_default_vpc" "handmade_tests-vpc" {
  tags = {
    Name = "handmade_tests-vpc"
  }
}

data "aws_availability_zones" "availabile_zones" {}


resource "aws_default_subnet" "handmade_tests-subnet-public1-us-east-1a" {
  availability_zone = data.aws_availability_zones.availabile_zones.names[0]

  tags = {
    Name = "default-subnet"
  }
}

resource "aws_security_group" "ec2_security_group" {
  name = "ec2-terraform-security-group"
  description = "ec2 security group built by terraform"
  vpc_id = aws_default_vpc.handmade_tests-vpc.id

  ingress {
    description = "http access"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "ssh access"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["108.46.61.62/32"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ec2 security group"
  }
}

data "aws_ami" "amazon_linux_2"{
    most_recent = true
    owners = ["amazon"]


  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }

}

resource "aws_instance" "ec2_instance" {
    ami = data.aws_ami.amazon_linux_2.id
    instance_type = "t3.micro"
    subnet_id = aws_default_subnet.handmade_tests-subnet-public1-us-east-1a.id
    vpc_security_group_ids =  [aws_security_group.ec2_security_group.id]
    key_name = "test-1"
    user_data = file("install_website.sh")

    tags = {
        Name = "tast terraform ec2"
    }
}

output "public_ipv4_address" {
    value = aws_instance.ec2_instance.public_ip
}