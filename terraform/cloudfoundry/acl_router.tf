resource "aws_network_acl_rule" "20_router" {
    network_acl_id = "${aws_network_acl.cf.id}"
    protocol = "tcp"
    rule_number = 20
    rule_action = "allow"
    from_port = 80
    to_port = 80
    cidr_block = "${var.infra_cidr_all}"
    egress = false
}

resource "aws_network_acl_rule" "21_router" {
    network_acl_id = "${aws_network_acl.cf.id}"
    protocol = "tcp"
    rule_number = 21
    rule_action = "allow"
    from_port = 443
    to_port = 443
    cidr_block = "${var.infra_cidr_all}"
    egress = false
}

resource "aws_network_acl_rule" "22_gorouter_replies" {
    network_acl_id = "${aws_network_acl.cf.id}"
    protocol = "tcp"
    rule_number = 22
    rule_action = "allow"
    from_port = 1024
    to_port = 61000
    cidr_block = "${var.cell_cidr_all}"
    egress = false
}
