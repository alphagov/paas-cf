output "system_domain_cert_id" {
  value = "${aws_iam_server_certificate.system.id}"
}

output "apps_domain_cert_id" {
  value = "${aws_iam_server_certificate.apps.id}"
}
