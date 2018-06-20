resource "datadog_monitor" "cdn_broker_healthy" {
  name                = "${format("%s cdn_broker healthy", var.env)}"
  type                = "service check"
  message             = "${format("Large portion of cdn brokers unhealthy. Check deployment state. @govpaas-alerting-%s@digital.cabinet-office.gov.uk", var.aws_account)}"
  escalation_message  = "Large portion of cdn brokers still unhealthy. Check deployment state."
  no_data_timeframe   = "7"
  require_full_window = true

  query = "${format("'http.can_connect'.over('deploy_env:%s','instance:cdn_broker','url:http://localhost:3000/healthcheck').by('*').last(1).pct_by_status()", var.env)}"

  thresholds {
    critical = 50
  }

  tags = ["deployment:${var.env}", "service:${var.env}_monitors", "job:cdn_broker"]
}
