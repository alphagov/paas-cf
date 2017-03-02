resource "aws_internet_gateway" "default" {
  vpc_id = "${aws_vpc.default.id}"
}

resource "aws_route_table" "internet" {
  vpc_id = "${aws_vpc.default.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.default.id}"
  }
}

resource "aws_route_table" "infra" {
  vpc_id = "${aws_vpc.default.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.default.id}"
  }
}

resource "aws_subnet" "infra" {
  count             = 2
  vpc_id            = "${aws_vpc.default.id}"
  cidr_block        = "${lookup(var.infra_cidrs, concat("zone", count.index))}"
  availability_zone = "${lookup(var.zones, concat("zone", count.index))}"
  map_public_ip_on_launch = true
  depends_on = ["aws_internet_gateway.default"]
  tags {
    Name = "${var.env}-infra-subnet-${count.index}"
  }
}

resource "aws_route_table_association" "infra" {
  count = 2
  subnet_id = "${element(aws_subnet.infra.*.id, count.index)}"
  route_table_id = "${aws_route_table.infra.id}"
}
