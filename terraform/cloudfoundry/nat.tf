resource "aws_eip" "cf" {
  count = "${var.cf_subnet_count}"
  vpc = true
}

resource "aws_nat_gateway" "cf" {
  count = "${var.cf_subnet_count}"
  allocation_id = "${element(aws_eip.cf.*.id, count.index)}"
  subnet_id = "${element(aws_subnet.cf.*.id, count.index)}"
}

resource "aws_route_table" "internet" {
  vpc_id = "${var.vpc_id}"
  count = "${var.cf_subnet_count}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${element(aws_nat_gateway.cf.*.id, count.index)}"
  }
}

resource "aws_route_table_association" "internet" {
  count          = "${var.cf_subnet_count}"
  subnet_id      = "${element(aws_subnet.cf.*.id, count.index)}"
  route_table_id = "${element(aws_route_table.internet.*.id, count.index)}"
}


