variable "system_dns_zone_id" {}

variable "system_dns_zone_name" {}

variable "system_domain_cert_id" {}

module "cloudfront_paas_product_page" {
  source = "./cloudfront_distribution"

  name    = "PaaS Product Page"
  aliases = ["www.${var.system_dns_zone_name}"]
  origin  = "govuk-paas.cloudapps.digital"
  comment = "Serve the govuk-paas under the gov.uk domain."

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
