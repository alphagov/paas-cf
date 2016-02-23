output "environment" {
  value = "${var.env}"
}

output "zone0" {
  value = "${var.zones.zone0}"
}

output "zone1" {
  value = "${var.zones.zone1}"
}

output "region" {
  value = "${var.region}"
}

output "bosh_subnet_id" {
  value = "${element(split(",", var.infra_subnet_ids), 0)}"
}

output "bosh_security_group" {
  value = "${aws_security_group.bosh.name}"
}

output "default_security_group" {
  value = "${aws_security_group.bosh_managed.name}"
}

output "microbosh_static_private_ip" {
  value = "${var.microbosh_static_private_ip}"
}

output "microbosh_static_public_ip" {
  value = "${aws_eip.bosh.public_ip}"
}

output "compiled_cache_bucket_host" {
  value = "s3-${var.region}.amazonaws.com"
}

output "compiled_cache_bucket_name" {
  value = "shared-cf-bosh-blobstore-${var.aws_account}"
}
output "cf1_subnet_id" {
  value = "${aws_subnet.cf.0.id}"
}

output "cf2_subnet_id" {
  value = "${aws_subnet.cf.1.id}"
}

output "cell1_subnet_id" {
  value = "${aws_subnet.cell.0.id}"
}

output "cell2_subnet_id" {
  value = "${aws_subnet.cell.1.id}"
}

output "router1_subnet_id" {
  value = "${aws_subnet.router.0.id}"
}

output "router2_subnet_id" {
  value = "${aws_subnet.router.1.id}"
}

output "ssh_elb_name" {
  value = "${aws_elb.ssh-proxy-router.name}"
}

output "cf_root_domain" {
  value = "${var.env}.${var.system_dns_zone_name}"
}

output "cf_apps_domain" {
  value = "${var.env}.${var.apps_dns_zone_name}"
}

output "elb_name" {
  value = "${aws_elb.router.name}"
}
