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
  count = var.enabled ? 1 : 0
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main[0].id
  count  = var.enabled ? 1 : 0
}

resource "aws_route_table" "main" {
  vpc_id = aws_vpc.main[0].id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main[0].id
  }
  count = var.enabled ? 1 : 0
}

module "healthcheck_a" {
  source = "./module"

  env                  = var.env
  ami                  = data.aws_ami.amazon_linux_2.id
  cidr                 = "10.0.1.0/24"
  region               = var.region
  aws_route_table_id   = aws_route_table.main[0].id
  vpc_id               = aws_vpc.main[0].id
  zone                 = "a"
  count                = var.enabled ? 1 : 0
  wait_for_healthcheck = var.wait_for_healthcheck
}

module "healthcheck_b" {
  source = "./module"

  env                  = var.env
  ami                  = data.aws_ami.amazon_linux_2.id
  cidr                 = "10.0.2.0/24"
  region               = var.region
  aws_route_table_id   = aws_route_table.main[0].id
  vpc_id               = aws_vpc.main[0].id
  zone                 = "b"
  count                = var.enabled ? 1 : 0
  wait_for_healthcheck = var.wait_for_healthcheck
}

module "healthcheck_c" {
  source = "./module"

  env                  = var.env
  ami                  = data.aws_ami.amazon_linux_2.id
  cidr                 = "10.0.3.0/24"
  region               = var.region
  aws_route_table_id   = aws_route_table.main[0].id
  vpc_id               = aws_vpc.main[0].id
  zone                 = "c"
  count                = var.enabled ? 1 : 0
  wait_for_healthcheck = var.wait_for_healthcheck
}
