resource "aws_network_acl_rule" "30_ephemeral_in" {
    network_acl_id = "${aws_network_acl.cf.id}"
    protocol = "tcp"
    rule_number = 30
    rule_action = "allow"
    from_port = 32768
    to_port = 61000
    cidr_block = "${var.vpc_cidr}"
    egress = false
}

resource "aws_network_acl_rule" "31_ephemeral_in" {
    network_acl_id = "${aws_network_acl.cf.id}"
    protocol = "udp"
    rule_number = 31
    rule_action = "allow"
    from_port = 32768
    to_port = 61000
    cidr_block = "${var.vpc_cidr}"
    egress = false
}


