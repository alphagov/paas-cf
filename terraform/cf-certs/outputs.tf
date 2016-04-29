output "system_domain_cert_arn" {
  value = "${aws_iam_server_certificate.system.arn}"
}

output "apps_domain_cert_arn" {
  value = "${aws_iam_server_certificate.apps.arn}"
}
