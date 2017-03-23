resource "aws_vpc_peering_connection" "vpc_peer" {
  count         = "${length(var.peer_vpc_ids)}"
  peer_owner_id = "${element(var.peer_account_ids, count.index)}"
  peer_vpc_id   = "${element(var.peer_vpc_ids, count.index)}"
  vpc_id        = "${var.vpc_id}"
}

resource "aws_route" "vpc_peer_route_0" {
  count                     = "${length(var.peer_vpc_ids)}"
  route_table_id            = "${aws_route_table.internet.0.id}"
  destination_cidr_block    = "${element(var.peer_cidrs, count.index)}"
  vpc_peering_connection_id = "${element(aws_vpc_peering_connection.vpc_peer.*.id, count.index)}"
}

resource "aws_route" "vpc_peer_route_1" {
  count                     = "${length(var.peer_vpc_ids)}"
  route_table_id            = "${aws_route_table.internet.1.id}"
  destination_cidr_block    = "${element(var.peer_cidrs, count.index)}"
  vpc_peering_connection_id = "${element(aws_vpc_peering_connection.vpc_peer.*.id, count.index)}"
}

resource "aws_route" "vpc_peer_route_2" {
  count                     = "${length(var.peer_vpc_ids)}"
  route_table_id            = "${aws_route_table.internet.2.id}"
  destination_cidr_block    = "${element(var.peer_cidrs, count.index)}"
  vpc_peering_connection_id = "${element(aws_vpc_peering_connection.vpc_peer.*.id, count.index)}"
}
