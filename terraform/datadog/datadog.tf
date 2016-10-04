variable "datadog_api_key" {}
variable "datadog_app_key" {}
variable "env" {}

provider "datadog" {
    api_key = "${var.datadog_api_key}"
    app_key = "${var.datadog_app_key}"
}

resource "datadog_monitor" "router" {
  name = "${format("%s router hosts", var.env)}"
  type = "service check"
  message = "Missing router hosts in environment {{host.environment}}. Notify: @the-multi-cloud-paas-team@digital.cabinet-office.gov.uk"
  escalation_message = "Missing router hosts! Check VM state."
  no_data_timeframe = "2"
  query = "${format("'datadog.agent.up'.over('environment:%s','job:router').by('*').last(1).pct_by_status()", var.env)}"

  thresholds {
    ok = 0
    warning = 0
    critical = 10
  }

  require_full_window = true
  tags {
    "environment" = "${var.env}"
    "job" = "router"
  }
}

