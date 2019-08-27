variable "pingdom_user" {}

variable "pingdom_password" {}

variable "pingdom_api_key" {}

variable "pingdom_account_email" {}

variable "apps_dns_zone_name" {}
variable "system_dns_zone_name" {}

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
  shouldcontain            = "END OF THIS PROJECT GUTENBERG EBOOK"
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
  shouldcontain            = "\"success\": true"
  encryption               = true
  resolution               = 1
  uselegacynotifications   = true
  sendtoemail              = true
  sendnotificationwhendown = 2
  notifywhenbackup         = true
  contactids               = ["${var.pingdom_contact_ids}"]
}

resource "pingdom_check" "cf_api_healthcheck" {
  type                     = "http"
  name                     = "PaaS CF API - ${var.env}"
  host                     = "api.${var.system_dns_zone_name}"
  url                      = "/v2/info"
  shouldcontain            = "api_version"
  encryption               = true
  resolution               = 1
  uselegacynotifications   = true
  sendtoemail              = true
  sendnotificationwhendown = 2
  notifywhenbackup         = true
  contactids               = ["${var.pingdom_contact_ids}"]
}

resource "pingdom_check" "paas_admin_healthcheck" {
  type                     = "http"
  name                     = "PaaS Admin - ${var.env}"
  host                     = "admin.${var.system_dns_zone_name}"
  url                      = "/healthcheck"
  shouldcontain            = "\"OK\""
  encryption               = true
  resolution               = 1
  uselegacynotifications   = true
  sendtoemail              = true
  sendnotificationwhendown = 2
  notifywhenbackup         = true
  contactids               = ["${var.pingdom_contact_ids}"]
}
