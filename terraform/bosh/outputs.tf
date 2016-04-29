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
  value = "${element(split(",", var.infra_subnet_ids), lookup(var.zone_index, var.bosh_az))}"
}

output "bosh_subnet_cidr" {
  value = "${lookup(var.infra_cidrs, concat("zone", lookup(var.zone_index, var.bosh_az)))}"
}

output "bosh_default_gw" {
  value = "${lookup(var.infra_gws, lookup(var.infra_cidrs, concat("zone", lookup(var.zone_index, var.bosh_az))))}"
}

output "microbosh_static_private_ip" {
  value = "${lookup(var.microbosh_ips, var.bosh_az)}"
}

output "bosh_security_group" {
  value = "${aws_security_group.bosh.name}"
}

output "default_security_group" {
  value = "${aws_security_group.bosh_managed.name}"
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

output "bosh_blobstore_bucket_name" {
  value = "${aws_s3_bucket.bosh-blobstore.id}"
}

output "bosh_db_address" {
  value = "${aws_db_instance.bosh.address}"
}

output "bosh_db_port" {
  value = "${aws_db_instance.bosh.port}"
}

output "bosh_db_username" {
  value = "${aws_db_instance.bosh.username}"
}

output "bosh_db_password" {
  value = "${aws_db_instance.bosh.password}"
}

output "bosh_db_dbname" {
  value = "${aws_db_instance.bosh.name}"
}

output "bosh_az" {
  value = "${var.bosh_az}"
}

output "bosh_fqdn" {
  value = "${aws_route53_record.bosh.name}"
}
