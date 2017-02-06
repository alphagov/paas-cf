variable "pingdom_user" {}

variable "pingdom_password" {}

variable "pingdom_api_key" {}

variable "pingdom_account_email" {}

variable "apps_dns_zone_name" {}

variable "env" {}

variable "pingdom_contact_ids" {
  type = "list"
}

provider "pingdom" {
  user          = "${var.pingdom_user}"
  password      = "${var.pingdom_password}"
  api_key       = "${var.pingdom_api_key}"
  account_email = "${var.pingdom_account_email}"
}

resource "pingdom_check" "paas_http_healthcheck" {
  type                     = "http"
  name                     = "PaaS HTTPS - ${var.env}"
  host                     = "healthcheck.${var.apps_dns_zone_name}"
  url                      = "/"
  encryption               = true
  resolution               = 1
  uselegacynotifications   = true
  sendtoemail              = true
  sendnotificationwhendown = 2
  notifywhenbackup         = true
  contactids               = ["${var.pingdom_contact_ids}"]
}

resource "pingdom_check" "paas_db_healthcheck" {
  type                     = "http"
  name                     = "PaaS DB - ${var.env}"
  host                     = "healthcheck.${var.apps_dns_zone_name}"
  url                      = "/db"
  encryption               = true
  resolution               = 1
  uselegacynotifications   = true
  sendtoemail              = true
  sendnotificationwhendown = 2
  notifywhenbackup         = true
  contactids               = ["${var.pingdom_contact_ids}"]
}
