resource "aws_network_acl_rule" "32_icmp_in" {
    network_acl_id = "${aws_network_acl.cf.id}"
    protocol = "icmp"
    rule_number = 32
    rule_action = "allow"
    cidr_block = "${var.vpc_cidr}"
    icmp_type = -1
    icmp_code = -1
    egress = false
}


