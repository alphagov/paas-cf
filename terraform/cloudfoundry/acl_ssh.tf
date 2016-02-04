resource "aws_network_acl_rule" "100_ssh" {
    network_acl_id = "${aws_network_acl.cf.id}"
    protocol = "tcp"
    rule_number = 100
    rule_action = "allow"
    from_port = 22
    to_port = 22
    cidr_block = "${var.vpc_cidr}"
    egress = false
}
