resource "aws_network_acl_rule" "30_cf-elb_out" {
    network_acl_id = "${aws_network_acl.router.id}"
    protocol = "tcp"
    rule_number = 31
    rule_action = "allow"
    from_port = 1024
    to_port = 65535
    cidr_block = "${var.infra_cidr_all}"
    egress = true
}

resource "aws_network_acl_rule" "100_internet_router_out" {
    network_acl_id = "${aws_network_acl.router.id}"
    protocol = -1
    rule_number = 100
    rule_action = "allow"
    cidr_block = "0.0.0.0/0"
    egress = true
}
