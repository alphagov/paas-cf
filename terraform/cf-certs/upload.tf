provider "aws" {
  region = "${var.region}"
}

resource "aws_iam_server_certificate" "system" {
  name_prefix       = "${var.env}-system-domain-"
  certificate_body  = "${var.system_domain_crt}"
  private_key       = "${var.system_domain_key}"
  certificate_chain = "${var.system_domain_intermediate_crt}"
  path              = "/cloudfront/${var.env}-system-domain/"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_server_certificate" "apps" {
  name_prefix       = "${var.env}-apps-domain-"
  certificate_body  = "${var.apps_domain_crt}"
  private_key       = "${var.apps_domain_key}"
  certificate_chain = "${var.apps_domain_intermediate_crt}"
  path              = "/cloudfront/${var.env}-apps-domain/"

  lifecycle {
    create_before_destroy = true
  }
}
