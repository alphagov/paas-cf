output "cf1_subnet_id" {
  value = "${element(concat(aws_subnet.cf.*.id, list("")), 0)}"
}

output "cf2_subnet_id" {
  value = "${element(concat(aws_subnet.cf.*.id, list("")), 1)}"
}

output "cf3_subnet_id" {
  value = "${element(concat(aws_subnet.cf.*.id, list("")), 2)}"
}

output "cell1_subnet_id" {
  value = "${element(concat(aws_subnet.cell.*.id, list("")), 0)}"
}

output "cell2_subnet_id" {
  value = "${element(concat(aws_subnet.cell.*.id, list("")), 1)}"
}

output "cell3_subnet_id" {
  value = "${element(concat(aws_subnet.cell.*.id, list("")), 2)}"
}

output "router1_subnet_id" {
  value = "${element(concat(aws_subnet.router.*.id, list("")), 0)}"
}

output "router2_subnet_id" {
  value = "${element(concat(aws_subnet.router.*.id, list("")), 1)}"
}

output "cf_root_domain" {
  value = "${var.system_dns_zone_name}"
}

output "cf_apps_domain" {
  value = "${var.apps_dns_zone_name}"
}

output "cf_rds_client_security_group" {
  value = "${aws_security_group.cf_rds_client.name}"
}

output "cdn_rds_client_security_group" {
  value = "${aws_security_group.cdn_rds_client.name}"
}

output "cf_db_address" {
  value = "${aws_db_instance.cf.address}"
}

output "cdn_db_connection_string" {
  value = "${format("postgresql://%v:%v@%v/%v", aws_db_instance.cdn.username, var.secrets_cdn_db_master_password, aws_db_instance.cdn.address, aws_db_instance.cdn.name)}"
}

output "cf_router_elb_name" {
  value = "${aws_elb.cf_router.name}"
}

output "cf_router_system_domain_elb_name" {
  value = "${aws_elb.cf_router_system_domain.name}"
}

output "cf_doppler_elb_name" {
  value = "${aws_elb.cf_doppler.name}"
}

output "cf_ssh_proxy_elb_name" {
  value = "${aws_elb.ssh_proxy.name}"
}

output "logsearch_ingestor_elb_name" {
  value = "${aws_elb.logsearch_ingestor.name}"
}

output "logsearch_ingestor_elb_dns_name" {
  value = "${aws_elb.logsearch_ingestor.dns_name}"
}

output "logsearch_elastic_master_elb_name" {
  value = "${aws_elb.logsearch_es_master.name}"
}

output "logsearch_elastic_master_elb_dns_name" {
  value = "${aws_elb.logsearch_es_master.dns_name}"
}

output "logsearch_elb_name" {
  value = "${aws_elb.logsearch_kibana.name}"
}

output "metrics_elb_name" {
  value = "${aws_elb.metrics.name}"
}

output "aws_backing_service_cidr_all" {
  value = "${var.aws_backing_service_cidr_all}"
}

output "rds_broker_db_clients_security_group" {
  value = "${aws_security_group.rds_broker_db_clients.name}"
}

output "cdn_broker_db_clients_security_group" {
  value = "${aws_security_group.cdn_rds_client.name}"
}

output "rds_broker_dbs_security_group_id" {
  value = "${aws_security_group.rds_broker_dbs.id}"
}

output "rds_broker_dbs_subnet_group" {
  value = "${aws_db_subnet_group.rds_broker.name}"
}

output "rds_broker_postgres95_db_parameter_group" {
  value = "${aws_db_parameter_group.rds_broker_postgres95.id}"
}

output "rds_broker_mysql57_db_parameter_group" {
  value = "${aws_db_parameter_group.rds_broker_mysql57.id}"
}

output "rds_broker_elb_name" {
  value = "${aws_elb.rds_broker.name}"
}

output "rds_broker_elb_dns_name" {
  value = "${aws_route53_record.rds_broker.fqdn}"
}

output "elasticache_broker_elb_name" {
  value = "${aws_elb.elasticache_broker.name}"
}

output "elasticache_broker_elb_dns_name" {
  value = "${aws_route53_record.elasticache_broker.fqdn}"
}

output "elasticache_broker_subnet_group_name" {
  value = "${aws_elasticache_subnet_group.elasticache_broker.name}"
}

output "elasticache_broker_clients_security_group" {
  value = "${aws_security_group.elasticache_broker_clients.name}"
}

output "elasticache_broker_instances_security_group_id" {
  value = "${aws_security_group.elasticache_broker_instances.id}"
}

output "cdn_broker_elb_name" {
  value = "${aws_elb.cdn_broker.name}"
}

output "cdn_broker_elb_dns_name" {
  value = "${aws_route53_record.cdn_broker.fqdn}"
}

output "cloud_controller_security_group" {
  value = "${aws_security_group.cloud_controller.name}"
}

output "cell_subnet_cidr_blocks" {
  value = ["${aws_subnet.cell.*.cidr_block}"]
}

output "router_subnet_cidr_blocks" {
  value = ["${aws_subnet.router.*.cidr_block}"]
}

output "nat_public_ips_csv" {
  value = "${join(",", aws_eip.cf.*.public_ip)}"
}

output "ses_smtp_host" {
  value = "email-smtp.${var.region}.amazonaws.com"
}

output "ses_smtp_aws_access_key_id" {
  value = "${aws_iam_access_key.ses_smtp.id}"
}

output "ses_smtp_password" {
  value = "${aws_iam_access_key.ses_smtp.ses_smtp_password}"
}

output "metrics_exporter_aws_access_key_id" {
  value = "${aws_iam_access_key.metrics_exporter.id}"
}

output "metrics_exporter_aws_secret_access_key" {
  value = "${aws_iam_access_key.metrics_exporter.secret}"
}
