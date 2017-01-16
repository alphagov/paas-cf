resource "aws_subnet" "cf" {
  count                   = "${var.zone_count}"
  vpc_id                  = "${var.vpc_id}"
  cidr_block              = "${lookup(var.cf_cidrs, format("zone%d", count.index))}"
  availability_zone       = "${lookup(var.zones, format("zone%d", count.index))}"
  map_public_ip_on_launch = false

  tags {
    Name = "${var.env}-cf-subnet-${count.index}"
  }
}

resource "aws_subnet" "router" {
  count                   = "${var.zone_count}"
  vpc_id                  = "${var.vpc_id}"
  cidr_block              = "${lookup(var.router_cidrs, format("zone%d", count.index))}"
  availability_zone       = "${lookup(var.zones, format("zone%d", count.index))}"
  map_public_ip_on_launch = false

  tags {
    Name = "${var.env}-router-subnet-${count.index}"
  }
}

resource "aws_subnet" "cell" {
  count                   = "${var.zone_count}"
  vpc_id                  = "${var.vpc_id}"
  cidr_block              = "${lookup(var.cell_cidrs, format("zone%d", count.index))}"
  availability_zone       = "${lookup(var.zones, format("zone%d", count.index))}"
  map_public_ip_on_launch = false

  tags {
    Name = "${var.env}-cell-subnet-${count.index}"
  }
}

resource "aws_subnet" "aws_backing_services" {
  count                   = "${var.zone_count}"
  vpc_id                  = "${var.vpc_id}"
  cidr_block              = "${lookup(var.aws_backing_service_cidrs, format("zone%d", count.index))}"
  availability_zone       = "${lookup(var.zones, format("zone%d", count.index))}"
  map_public_ip_on_launch = false

  tags {
    Name = "${var.env}-aws-backing-service-${count.index}"
  }
}
