resource "aws_network_acl_rule" "70_cloudcontroller" {
    network_acl_id = "${aws_network_acl.cf.id}"
    protocol = "tcp"
    rule_number = 70
    rule_action = "allow"
    from_port = 9022
    to_port = 9022
    cidr_block = "${var.cell_cidr_all}"
    egress = false
}
