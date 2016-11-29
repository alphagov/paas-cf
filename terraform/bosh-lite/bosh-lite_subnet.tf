resource "aws_internet_gateway" "default" {
  vpc_id = "${aws_vpc.bosh-lite-vpc.id}"

  tags {
    Name       = "${var.env}-bosh-lite-igw"
    Created-by = "terraform-bosh-lite"
  }
}

resource "aws_route_table" "bosh-lite" {
  vpc_id = "${aws_vpc.bosh-lite-vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.default.id}"
  }

  tags {
    Name       = "${var.env}-bosh-lite-rtb"
    Created-by = "terraform-bosh-lite"
  }
}

resource "aws_subnet" "bosh-lite" {
  count             = "${length(var.bosh_lite_zones)}"
  vpc_id            = "${aws_vpc.bosh-lite-vpc.id}"
  cidr_block        = "${lookup(var.bosh_lite_cidrs, format("zone%d", count.index))}"
  availability_zone = "${lookup(var.bosh_lite_zones, format("zone%d", count.index))}"
  depends_on        = ["aws_internet_gateway.default"]

  map_public_ip_on_launch = true

  tags {
    Name       = "${var.env}-bosh-lite-subnet-${count.index}"
    Created-by = "terraform-bosh-lite"
  }
}

resource "aws_route_table_association" "bosh-lite" {
  count          = "${length(var.bosh_lite_zones)}"
  subnet_id      = "${element(aws_subnet.bosh-lite.*.id, count.index)}"
  route_table_id = "${aws_route_table.bosh-lite.id}"
}
