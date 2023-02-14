data "aws_subnets" "aws_backing_service" {
  filter {
    name   = "tag:Name"
    values = local.subnet_names
  }
}

resource "aws_subnet" "aws_dms_replication_zone_0" {
  for_each = local.migrations

  vpc_id            = var.vpc_id
  cidr_block        = cidrsubnet(var.dms_cidrs[0], 6, each.value.index)
  availability_zone = var.zones["zone0"]

  map_public_ip_on_launch = false

  tags = {
    Build       = "terraform"
    Resource    = "aws_subnet"
    Environment = var.env
    Name        = "${var.env}-aws-dms-zone0-${each.value.index}"
  }
}

resource "aws_subnet" "aws_dms_replication_zone_1" {
  for_each = local.migrations

  vpc_id            = var.vpc_id
  cidr_block        = cidrsubnet(var.dms_cidrs[1], 6, each.value.index)
  availability_zone = var.zones["zone1"]

  map_public_ip_on_launch = false

  tags = {
    Build       = "terraform"
    Resource    = "aws_subnet"
    Environment = var.env
    Name        = "${var.env}-aws-dms-zone1-${each.value.index}"
  }
}

resource "aws_subnet" "aws_dms_replication_zone_2" {
  for_each = local.migrations

  vpc_id            = var.vpc_id
  cidr_block        = cidrsubnet(var.dms_cidrs[2], 6, each.value.index)
  availability_zone = var.zones["zone2"]

  map_public_ip_on_launch = false

  tags = {
    Build       = "terraform"
    Resource    = "aws_subnet"
    Environment = var.env
    Name        = "${var.env}-aws-dms-zone2-${each.value.index}"
  }
}
