resource "aws_network_acl_rule" "120_local_drop" {
    network_acl_id = "${aws_network_acl.cf.id}"
    protocol = "tcp"
    rule_number = 120
    rule_action = "deny"
    from_port = 0
    to_port = 32767
    cidr_block = "${var.vpc_cidr}"
    egress = false
}
