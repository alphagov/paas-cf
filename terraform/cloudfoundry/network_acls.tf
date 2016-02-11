resource "aws_network_acl" "cf" {
    vpc_id = "${var.vpc_id}"
    subnet_ids = ["${aws_subnet.cf.*.id}"]
}

resource "aws_network_acl" "cell" {
    vpc_id = "${var.vpc_id}"
    subnet_ids = ["${aws_subnet.cell.*.id}"]
}
