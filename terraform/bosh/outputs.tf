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
	value = "${var.subnet0_id}"
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

output "aws_secret_access_key" {
	value = "${var.AWS_SECRET_ACCESS_KEY}"
}

output "aws_access_key_id" {
       value = "${var.AWS_ACCESS_KEY_ID}"
}

output "compiled_cache_bucket_access_key_id" {
	value = "${var.AWS_ACCESS_KEY_ID}"
}

output "compiled_cache_bucket_secret_access_key" {
	value = "${var.AWS_SECRET_ACCESS_KEY}"
}

output "compiled_cache_bucket_host" {
	value = "s3-${var.region}.amazonaws.com"
}

# TODO: Generate a key pair per installation
output "key_pair_name" {
	value = "${var.key_pair_name}"
}
