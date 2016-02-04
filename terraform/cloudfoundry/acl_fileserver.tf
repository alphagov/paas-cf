resource "aws_network_acl_rule" "40_fileserver" {
    network_acl_id = "${aws_network_acl.cf.id}"
    protocol = "tcp"
    rule_number = 40
    rule_action = "allow"
    from_port = 8080
    to_port = 8080
    cidr_block = "${var.cell_cidr_all}"
    egress = false
}
