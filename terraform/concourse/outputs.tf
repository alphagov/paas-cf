output "concourse_db_address" {
  value = "${aws_db_instance.concourse.address}"
}

output "concourse_elastic_ip" {
  value = "${aws_eip.concourse.public_ip}"
}

output "concourse_security_group" {
  value = "${aws_security_group.concourse.name}"
}

output "concourse_security_group_id" {
  value = "${aws_security_group.concourse.id}"
}

output "concourse_db_address" {
  value = "${aws_db_instance.concourse.address}"
}
