provider "aws" {
  region = "${var.region}"
}

resource "aws_iam_server_certificate" "router" {
  name_prefix = "${var.env}-router-"
  certificate_body = "${var.router_external_crt}"
  private_key = "${var.router_external_key}"
  lifecycle {
    create_before_destroy = true
  }
}
