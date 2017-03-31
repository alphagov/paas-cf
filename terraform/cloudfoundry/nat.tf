resource "aws_eip" "cf" {
  count = "${var.zone_count}"
  vpc   = true
}

resource "aws_nat_gateway" "cf" {
  count         = "${var.zone_count}"
  allocation_id = "${element(aws_eip.cf.*.id, count.index)}"
  subnet_id     = "${element(split(",", var.infra_subnet_ids), count.index)}"
}

resource "aws_route_table" "internet" {
  vpc_id = "${var.vpc_id}"
  count  = "${var.zone_count}"
}

resource "aws_route" "internet" {
  count                  = "${var.zone_count}"
  route_table_id         = "${element(aws_route_table.internet.*.id, count.index)}"
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = "${element(aws_nat_gateway.cf.*.id, count.index)}"
}

resource "aws_route_table_association" "internet" {
  count          = "${var.zone_count}"
  subnet_id      = "${element(aws_subnet.cf.*.id, count.index)}"
  route_table_id = "${element(aws_route_table.internet.*.id, count.index)}"
}

resource "aws_route_table_association" "cell_internet" {
  count          = "${var.zone_count}"
  subnet_id      = "${element(aws_subnet.cell.*.id, count.index)}"
  route_table_id = "${element(aws_route_table.internet.*.id, count.index)}"
}

resource "aws_route_table_association" "router_internet" {
  count          = "${var.zone_count}"
  subnet_id      = "${element(aws_subnet.router.*.id, count.index)}"
  route_table_id = "${element(aws_route_table.internet.*.id, count.index)}"
}
