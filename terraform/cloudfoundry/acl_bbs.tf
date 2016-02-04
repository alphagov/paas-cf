resource "aws_network_acl_rule" "60_bbs" {
    network_acl_id = "${aws_network_acl.cf.id}"
    protocol = "tcp"
    rule_number = 60
    rule_action = "allow"
    from_port = 8889
    to_port = 8889
    cidr_block = "${var.cell_cidr_all}"
    egress = false
}
