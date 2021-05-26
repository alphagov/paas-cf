provider "aws" {
  region = var.region
}

data "aws_subnet_ids" "selected" {
  vpc_id = var.vpc_id

  filter {
    name   = "availability-zone"
    values = [var.az]
  }
}

resource "aws_network_acl" "disable_az" {
  vpc_id = var.vpc_id

  # We will be relying on the default DENY ALL rule provided by AWS.

  tags = {
    Name = "disable_az_${var.az}"
  }

  subnet_ids = [for s in data.aws_subnet_ids.selected.ids : s]
}
