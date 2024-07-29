variable "apps_dns_zone_name" { type = string }
variable "env" { type = string }
variable "pingdom_account_email" { type = string }
variable "pingdom_api_key" { type = string }
variable "pingdom_contact_ids" { type = list(string) }
variable "pingdom_password" { type = string }
variable "pingdom_user" { type = string }
variable "system_dns_zone_name" { type = string }

provider "pingdom" {
  api_token = var.pingdom_api_key
}

resource "pingdom_check" "paas_http_healthcheck" {
  type                     = "http"
  name                     = "PaaS HTTPS - ${var.env}"
  host                     = "healthcheck.${var.apps_dns_zone_name}"
  url                      = "/"
  shouldcontain            = "END OF THIS PROJECT GUTENBERG EBOOK"
  encryption               = true
  resolution               = 1
  sendnotificationwhendown = 2
  responsetime_threshold   = 10000
  notifywhenbackup         = true
  userids                  = var.pingdom_contact_ids
}

resource "pingdom_check" "paas_db_healthcheck" {
  type                     = "http"
  name                     = "PaaS DB - ${var.env}"
  host                     = "healthcheck.${var.apps_dns_zone_name}"
  url                      = "/db"
  shouldcontain            = "\"success\": true"
  encryption               = true
  resolution               = 1
  sendnotificationwhendown = 2
  responsetime_threshold   = 10000
  notifywhenbackup         = true
  userids                  = var.pingdom_contact_ids
}

resource "pingdom_check" "cf_api_healthcheck" {
  type                     = "http"
  name                     = "PaaS CF API - ${var.env}"
  host                     = "api.${var.system_dns_zone_name}"
  url                      = "/v2/info"
  shouldcontain            = "api_version"
  encryption               = true
  resolution               = 1
  sendnotificationwhendown = 2
  responsetime_threshold   = 3000
  notifywhenbackup         = true
  userids                  = var.pingdom_contact_ids
}

resource "pingdom_check" "paas_admin_healthcheck" {
  type                     = "http"
  name                     = "PaaS Admin - ${var.env}"
  host                     = "admin.${var.system_dns_zone_name}"
  url                      = "/healthcheck"
  shouldcontain            = "\"OK\""
  encryption               = true
  resolution               = 1
  sendnotificationwhendown = 2
  responsetime_threshold   = 3000
  notifywhenbackup         = true
  userids                  = var.pingdom_contact_ids
}
