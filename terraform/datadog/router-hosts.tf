resource "datadog_monitor" "router" {
  name = "${data.null_data_source.datadog.inputs.env} router hosts"
  type = "service check"
  message = "Missing router hosts in environment {{host.environment}}. Notify: @the-multi-cloud-paas-team@digital.cabinet-office.gov.uk"
  escalation_message = "Missing router hosts! Check VM state."
  no_data_timeframe = "2"
  query = "'datadog.agent.up'.over('environment:${data.null_data_source.datadog.inputs.env}','job:router').by('*').last(1).pct_by_status()"

  thresholds {
    ok = 0
    warning = 0
    critical = 10
  }

  require_full_window = true
  tags {
    "environment" = "${data.null_data_source.datadog.inputs.env}"
    "job" = "router"
  }
}
