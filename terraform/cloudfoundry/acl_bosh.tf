resource "aws_network_acl_rule" "110_bosh" {
    network_acl_id = "${aws_network_acl.cf.id}"
    protocol = "tcp"
    rule_number = 110
    rule_action = "allow"
    from_port = 0
    to_port = 65535
    cidr_block = "${var.microbosh_static_private_ip}/32"
    egress = false
}
