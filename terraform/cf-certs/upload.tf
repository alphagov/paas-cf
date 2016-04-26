provider "aws" {
  region = "${var.region}"
}

resource "aws_iam_server_certificate" "system" {
  name_prefix = "${var.env}-system-domain-"
  certificate_body = "${var.system_domain_crt}"
  private_key = "${var.system_domain_key}"
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_server_certificate" "apps" {
  name_prefix = "${var.env}-apps-domain-"
  certificate_body = "${var.apps_domain_crt}"
  private_key = "${var.apps_domain_key}"
  lifecycle {
    create_before_destroy = true
  }
}
