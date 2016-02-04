resource "aws_network_acl_rule" "90_cf_local_in" {
    network_acl_id = "${aws_network_acl.cf.id}"
    protocol = -1
    rule_number = 90
    rule_action = "allow"
    cidr_block = "${var.cf_cidr_all}"
    egress = false
}
