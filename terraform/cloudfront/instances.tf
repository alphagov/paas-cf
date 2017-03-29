variable "system_dns_zone_id" {}

variable "system_dns_zone_name" {}

variable "system_domain_cert_id" {}

module "cloudfront_paas_product_page" {
  source = "./cloudfront_distribution"

  name    = "PaaS Product Page"
  aliases = ["www.${var.system_dns_zone_name}"]
  origin  = "paas-product-page.cloudapps.digital"
  comment = "Serve the paas-product-page under the gov.uk domain."

  env                   = "${var.env}"
  system_dns_zone_name  = "${var.system_dns_zone_name}"
  system_dns_zone_id    = "${var.system_dns_zone_id}"
  system_domain_cert_id = "${var.system_domain_cert_id}"
}

module "cloudfront_paas_docs" {
  source = "./cloudfront_distribution"

  name    = "PaaS Docs"
  aliases = ["docs.${var.system_dns_zone_name}"]
  origin  = "paas-tech-docs.cloudapps.digital"
  comment = "Serve the paas-tech-docs under the gov.uk domain."

  env                   = "${var.env}"
  system_dns_zone_name  = "${var.system_dns_zone_name}"
  system_dns_zone_id    = "${var.system_dns_zone_id}"
  system_domain_cert_id = "${var.system_domain_cert_id}"
}

module "redirect_paas_product_page" {
  source = "./cloudfront_redirect"

  name = "${var.env}-paas-product-page"

  aliases         = ["${var.system_dns_zone_name}"]
  redirect_target = "https://www.${var.system_dns_zone_name}"

  env            = "${var.env}"
  dns_zone_id    = "${var.system_dns_zone_id}"
  domain_cert_id = "${var.system_domain_cert_id}"
}
