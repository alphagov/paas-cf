resource "aws_network_acl_rule" "100_internet_cf_out" {
    network_acl_id = "${aws_network_acl.cf.id}"
    protocol = "all"
    rule_number = 100
    rule_action = "allow"
    cidr_block = "0.0.0.0/0"
    egress = true
}
