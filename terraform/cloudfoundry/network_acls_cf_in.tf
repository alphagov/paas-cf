resource "aws_network_acl_rule" "10_consul_in" {
    network_acl_id = "${aws_network_acl.cf.id}"
    protocol = "tcp"
    rule_number = 10
    rule_action = "allow"
    from_port = 8300
    to_port = 8500
    cidr_block = "${var.cell_cidr_all}"
    egress = false
}

resource "aws_network_acl_rule" "11_consul_in" {
    network_acl_id = "${aws_network_acl.cf.id}"
    protocol = "udp"
    rule_number = 11
    rule_action = "allow"
    from_port = 8300
    to_port = 8500
    cidr_block = "${var.cell_cidr_all}"
    egress = false
}

resource "aws_network_acl_rule" "30_ephemeral_in" {
    network_acl_id = "${aws_network_acl.cf.id}"
    protocol = "tcp"
    rule_number = 30
    rule_action = "allow"
    from_port = 32768
    to_port = 61000
    cidr_block = "${var.vpc_cidr}"
    egress = false
}

resource "aws_network_acl_rule" "31_ephemeral_in" {
    network_acl_id = "${aws_network_acl.cf.id}"
    protocol = "udp"
    rule_number = 31
    rule_action = "allow"
    from_port = 32768
    to_port = 61000
    cidr_block = "${var.vpc_cidr}"
    egress = false
}

resource "aws_network_acl_rule" "32_icmp_in" {
    network_acl_id = "${aws_network_acl.cf.id}"
    protocol = "icmp"
    rule_number = 32
    rule_action = "allow"
    cidr_block = "${var.vpc_cidr}"
    icmp_type = -1
    icmp_code = -1
    egress = false
}

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

resource "aws_network_acl_rule" "90_cf_local_in" {
    network_acl_id = "${aws_network_acl.cf.id}"
    protocol = "all"
    rule_number = 90
    rule_action = "allow"
    cidr_block = "${var.cf_cidr_all}"
    egress = false
}

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

resource "aws_network_acl_rule" "115_router_in" {
    network_acl_id = "${aws_network_acl.cf.id}"
    protocol = "all"
    rule_number = 115
    rule_action = "allow"
    from_port = 1024
    to_port = 65535
    cidr_block = "${var.router_cidr_all}"
    egress = false
}

resource "aws_network_acl_rule" "116_router_consul_in" {
    network_acl_id = "${aws_network_acl.cf.id}"
    protocol = "udp"
    rule_number = 116
    rule_action = "allow"
    from_port = 8300
    to_port = 8500
    cidr_block = "${var.router_cidr_all}"
    egress = false
}

resource "aws_network_acl_rule" "117_kibana_and_es" {
    network_acl_id = "${aws_network_acl.cf.id}"
    protocol = "tcp"
    rule_number = 117
    rule_action = "allow"
    from_port = 5601
    to_port = 9300
    cidr_block = "${var.infra_cidr_all}"
    egress = false
}

resource "aws_network_acl_rule" "118_ingestor_syslog" {
    network_acl_id = "${aws_network_acl.cf.id}"
    protocol = "tcp"
    rule_number = 118
    rule_action = "allow"
    from_port = 2514
    to_port = 5514
    cidr_block = "${var.infra_cidr_all}"
    egress = false
}

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

resource "aws_network_acl_rule" "130_internet_cf_in" {
    network_acl_id = "${aws_network_acl.cf.id}"
    protocol = "all"
    rule_number = 130
    rule_action = "allow"
    cidr_block = "0.0.0.0/0"
    egress = false
}
