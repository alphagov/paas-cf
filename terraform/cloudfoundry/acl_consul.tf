resource "aws_network_acl_rule" "10_consul_in" {
    network_acl_id = "${aws_network_acl.cf.id}"
    protocol = "tcp"
    rule_number = 10
    rule_action = "allow"
    from_port = 8300
    to_port = 8500
    cidr_block = "${var.cell_cidr_all}"
    egress = false
}

resource "aws_network_acl_rule" "11_consul_in" {
    network_acl_id = "${aws_network_acl.cf.id}"
    protocol = "udp"
    rule_number = 11
    rule_action = "allow"
    from_port = 8300
    to_port = 8500
    cidr_block = "${var.cell_cidr_all}"
    egress = false
}


