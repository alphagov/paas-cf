provider "aws" {
  region = var.region
}

data "aws_subnets" "selected" {
  filter {
    name = "vpc-id"
    values = [var.vpc_id]
  }
  filter {
    name   = "availability-zone"
    values = [var.az]
  }
}

data "aws_subnets" "excluded" {
  filter {
    name = "vpc-id"
    values = [var.vpc_id]
  }
  filter {
    name = "tag:Name"
    values = ["*-infra-${var.az}", "*-backing-service-*"]
  }
}

resource "aws_network_acl" "disable_az" {
  vpc_id = var.vpc_id

  # We will be relying on the default DENY ALL rule provided by AWS.

  tags = {
    Name = "disable_az_${var.az}"
  }

  # All subnets, excluding the infra, and backing-service ones
  subnet_ids = [for s in data.aws_subnets.selected.ids : s if !contains(data.aws_subnets.excluded.ids, s)]
}
