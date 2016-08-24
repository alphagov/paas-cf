output "environment" {
  value = "${var.env}"
}

output "region" {
  value = "${var.region}"
}

output "vpc_cidr" {
  value = "${aws_vpc.myvpc.cidr_block}"
}

output "ssh_security_group" {
  value = "${aws_security_group.office-access-ssh.name}"
}

output "vpc_id" {
  value = "${aws_vpc.myvpc.id}"
}

output "subnet0_id" {
  value = "${aws_subnet.infra.0.id}"
}

output "zone0" {
  value = "${var.zones.zone0}"
}

output "zone1" {
  value = "${var.zones.zone1}"
}

output "zone2" {
  value = "${var.zones.zone2}"
}

output "infra_subnet_ids" {
  value = "${join(",", aws_subnet.infra.*.id)}"
}
