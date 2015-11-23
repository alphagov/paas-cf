output "bastion_ip" {
  value = "${aws_instance.bastion.public_ip}"
}

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

output "dns_zone_name" {
        value = "${var.dns_zone_name}"
}


output "aws_secret_access_key" {
	value = "${var.AWS_SECRET_ACCESS_KEY}"
}

output "aws_access_key_id" {
       value = "${var.AWS_ACCESS_KEY_ID}"
}
