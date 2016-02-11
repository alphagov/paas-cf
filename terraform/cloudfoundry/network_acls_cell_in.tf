resource "aws_network_acl_rule" "90_local_in" {
    network_acl_id = "${aws_network_acl.cell.id}"
    protocol = -1
    rule_number = 90
    rule_action = "allow"
    cidr_block = "${var.vpc_cidr}"
    egress = false
}

resource "aws_network_acl_rule" "100_internet_cell_in" {
    network_acl_id = "${aws_network_acl.cell.id}"
    protocol = "tcp"
    rule_number = 100
    rule_action = "allow"
    cidr_block = "0.0.0.0/0"
    from_port = 32768
    to_port = 61000
    egress = false
}

resource "aws_network_acl_rule" "101_internet_cell_in" {
    network_acl_id = "${aws_network_acl.cell.id}"
    protocol = "udp"
    rule_number = 101
    rule_action = "allow"
    cidr_block = "0.0.0.0/0"
    from_port = 32768
    to_port = 61000
    egress = false
}
