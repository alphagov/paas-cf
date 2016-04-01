output "router_external_cert_arn" {
  value = "${aws_iam_server_certificate.router.arn}"
}
