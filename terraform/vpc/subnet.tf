resource "aws_internet_gateway" "default" {
  vpc_id = "${aws_vpc.myvpc.id}"
}

resource "aws_route_table" "infra" {
  vpc_id = "${aws_vpc.myvpc.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.default.id}"
  }
}

resource "aws_subnet" "infra" {
  count             = "${var.zone_count}"
  vpc_id            = "${aws_vpc.myvpc.id}"
  cidr_block        = "${lookup(var.infra_cidrs, format("zone%d", count.index))}"
  availability_zone = "${lookup(var.zones,       format("zone%d", count.index))}"
  depends_on        = ["aws_internet_gateway.default"]
  tags {
    Name = "${var.env}-infra-${lookup(var.zones, format("zone%d", count.index))}"
  }
}

resource "aws_route_table_association" "infra" {
  count          = "${var.zone_count}"
  subnet_id      = "${element(aws_subnet.infra.*.id, count.index)}"
  route_table_id = "${aws_route_table.infra.id}"
}

