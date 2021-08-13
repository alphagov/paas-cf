provider "aws" {
  region = var.region
}

data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-ebs"]
  }
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  enable_dns_hostnames = true

  tags = {
    Name = "az-healthcheck"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "main" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
}

module "healthcheck_a" {
  source = "./module"

  ami                = data.aws_ami.amazon_linux_2.id
  cidr               = "10.0.1.0/24"
  region             = var.region
  aws_route_table_id = aws_route_table.main.id
  vpc_id             = aws_vpc.main.id
  zone               = "a"
}

module "healthcheck_b" {
  source = "./module"

  ami                = data.aws_ami.amazon_linux_2.id
  cidr               = "10.0.2.0/24"
  region             = var.region
  aws_route_table_id = aws_route_table.main.id
  vpc_id             = aws_vpc.main.id
  zone               = "b"
}

module "healthcheck_c" {
  source = "./module"

  ami                = data.aws_ami.amazon_linux_2.id
  cidr               = "10.0.3.0/24"
  region             = var.region
  aws_route_table_id = aws_route_table.main.id
  vpc_id             = aws_vpc.main.id
  zone               = "c"
}
