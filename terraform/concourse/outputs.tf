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

output "git_concourse_pool_clone_full_url_ssh" {
  # convert the ssh:// url to a scp like connect string and add the git user
  value = "ssh://${aws_iam_user_ssh_key.git.ssh_public_key_id}@${replace(aws_codecommit_repository.concourse-pool.clone_url_ssh, "/^ssh://([^/]+)//", "$1/")}"
}

output "concourse_key_pair_name" {
  value = "${aws_key_pair.concourse_key_pair.key_name}"
}
