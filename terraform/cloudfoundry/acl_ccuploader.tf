resource "aws_network_acl_rule" "50_ccuploader" {
    network_acl_id = "${aws_network_acl.cf.id}"
    protocol = "tcp"
    rule_number = 50
    rule_action = "allow"
    from_port = 9090
    to_port = 9090
    cidr_block = "${var.cell_cidr_all}"
    egress = false
}
