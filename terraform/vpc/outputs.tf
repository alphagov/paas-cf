output "environment" {
  value = "${var.env}"
}

output "region" {
  value = "${var.region}"
}

output "vpc" {
  value = "${aws_vpc.myvpc.id}"
}

output "vpc-cidr" {
  value = "${aws_vpc.myvpc.cidr_block}"
}

output "office-access-sg-id" {
  value = "${aws_security_group.office-access.id}"
}

output "infrastructure-subnets" {
  value = "${join(",", aws_subnet.infra.*.id)}"
}

