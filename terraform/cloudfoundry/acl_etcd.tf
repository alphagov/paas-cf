resource "aws_network_acl_rule" "80_etcd" {
    network_acl_id = "${aws_network_acl.cf.id}"
    protocol = "tcp"
    rule_number = 80
    rule_action = "allow"
    from_port = 4001
    to_port = 4001
    cidr_block = "${var.cell_cidr_all}"
    egress = false
}
