resource "aws_network_acl_rule" "20_cf_in" {
    network_acl_id = "${aws_network_acl.router.id}"
    protocol = "tcp"
    rule_number = 20
    rule_action = "allow"
    from_port = 1024
    to_port = 65535
    cidr_block = "${var.cf_cidr_all}"
    egress = false
}

resource "aws_network_acl_rule" "21_elb_in" {
    network_acl_id = "${aws_network_acl.router.id}"
    protocol = "tcp"
    rule_number = 21
    rule_action = "allow"
    from_port = 1024
    to_port = 65535
    cidr_block = "${var.infra_cidr_all}"
    egress = false
}

resource "aws_network_acl_rule" "22_app_replies" {
    network_acl_id = "${aws_network_acl.router.id}"
    protocol = "tcp"
    rule_number = 22
    rule_action = "allow"
    from_port = 1024
    to_port = 65535
    cidr_block = "${var.cell_cidr_all}"
    egress = false
}

resource "aws_network_acl_rule" "32_router_icmp_in" {
    network_acl_id = "${aws_network_acl.router.id}"
    protocol = "icmp"
    rule_number = 32
    rule_action = "allow"
    cidr_block = "${var.vpc_cidr}"
    icmp_type = -1
    icmp_code = -1
    egress = false
}

resource "aws_network_acl_rule" "33_ssh" {
    network_acl_id = "${aws_network_acl.router.id}"
    protocol = "tcp"
    rule_number = 33
    rule_action = "allow"
    from_port = 22
    to_port = 22
    cidr_block = "${var.infra_cidr_all}"
    egress = false
}

resource "aws_network_acl_rule" "101_internet_router_in" {
    network_acl_id = "${aws_network_acl.router.id}"
    protocol = -1
    rule_number = 101
    rule_action = "allow"
    cidr_block = "0.0.0.0/0"
    egress = false
}
