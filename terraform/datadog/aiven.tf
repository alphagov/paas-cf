resource "datadog_monitor" "aiven_cost_threshold" {
  name                = "${format("%s aiven cost is high", var.env)}"
  type                = "metric alert"
  message             = "${format("Aiven cost is high, possibly need to alert finance. @govpaas-alerting-%s@digital.cabinet-office.gov.uk", var.aws_account)}"
  no_data_timeframe   = "7"
  require_full_window = true

  query = "${format("max(last_1h):max:aiven.estimated.cost{deploy_env:%s} > 3100.0", var.env)}"

  thresholds {
    warning  = "2600.00"
    critical = "3100.00"
  }

  tags = ["deployment:${var.env}", "service:${var.env}_monitors"]
}
