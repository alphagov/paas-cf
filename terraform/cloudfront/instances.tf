variable "system_dns_zone_id" {}

variable "system_dns_zone_name" {}

variable "apps_dns_zone_name" {}

# Cloudfront requires an ACM cert in us-east-1
provider "aws" {
  region = "us-east-1"
  alias  = "us-east-1"
}

data "aws_acm_certificate" "system" {
  domain   = "*.${var.system_dns_zone_name}"
  statuses = ["ISSUED"]
  provider = "aws.us-east-1"
}

module "cloudfront_paas_product_page" {
  source = "./cloudfront_distribution"

  name    = "PaaS Product Page"
  aliases = ["www.${var.system_dns_zone_name}"]
  origin  = "${var.apps_dns_zone_name}"
  comment = "Serve the paas-product-page under the gov.uk domain."

  env                        = "${var.env}"
  system_dns_zone_name       = "${var.system_dns_zone_name}"
  system_dns_zone_id         = "${var.system_dns_zone_id}"
  system_domain_acm_cert_arn = "${data.aws_acm_certificate.system.arn}"
}

module "cloudfront_paas_docs" {
  source = "./cloudfront_distribution"

  name    = "PaaS Docs"
  aliases = ["docs.${var.system_dns_zone_name}"]
  origin  = "${var.apps_dns_zone_name}"
  comment = "Serve the paas-tech-docs under the gov.uk domain."

  env                        = "${var.env}"
  system_dns_zone_name       = "${var.system_dns_zone_name}"
  system_dns_zone_id         = "${var.system_dns_zone_id}"
  system_domain_acm_cert_arn = "${data.aws_acm_certificate.system.arn}"
}

module "redirect_paas_product_page" {
  source = "./cloudfront_redirect"

  name = "${var.env}-paas-product-page"

  aliases         = ["${var.system_dns_zone_name}"]
  redirect_target = "https://www.${var.system_dns_zone_name}"

  env                 = "${var.env}"
  dns_zone_id         = "${var.system_dns_zone_id}"
  domain_acm_cert_arn = "${data.aws_acm_certificate.system.arn}"
}
