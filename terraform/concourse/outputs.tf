output "concourse_elastic_ip" {
  value = "${aws_eip.concourse.public_ip}"
}

output "concourse_security_group" {
  value = "${aws_security_group.concourse.name}"
}

output "concourse_security_group_id" {
  value = "${aws_security_group.concourse.id}"
}

output "concourse_elb_name" {
  value = "${aws_elb.concourse.name}"
}

output "concourse_dns_name" {
  value = "${aws_route53_record.deployer-concourse.fqdn}"
}
