output "cf1_subnet_id" {
  value = "${aws_subnet.cf.0.id}"
}

output "cf2_subnet_id" {
  value = "${aws_subnet.cf.1.id}"
}

output "cf3_subnet_id" {
  value = "${aws_subnet.cf.2.id}"
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

output "cf_rds_client_security_group" {
  value = "${aws_security_group.cf_rds_client.name}"
}

output "cf_db_address" {
  value = "${aws_db_instance.cf.address}"
}

output "ingestor_elb_name" {
  value = "${aws_elb.ingestor_elb.name}"
}

output "ingestor_elb_dns_name" {
  value = "${aws_elb.ingestor_elb.dns_name}"
}

output "elastic_master_elb_name" {
  value = "${aws_elb.es_master_elb.name}"
}

output "elastic_master_elb_dns_name" {
  value = "${aws_elb.es_master_elb.dns_name}"
}
