resource "datadog_monitor" "route_emitter_process_running" {
  name                = "${format("%s route-emitter process running", var.env)}"
  type                = "service check"
  message             = "${format("route-emitter process not running. Check router state. @govpaas-alerting-%s@digital.cabinet-office.gov.uk", var.aws_account)}"
  notify_no_data      = false
  require_full_window = true

  query = "${format("'process.up'.over('deploy_env:%s','process:route-emitter').last(4).count_by_status()", var.env)}"

  thresholds {
    ok       = 1
    warning  = 2
    critical = 3
  }

  tags = ["deployment:${var.env}", "service:${var.env}_monitors", "job:route_emitter"]
}

resource "datadog_monitor" "route_emitter_healthy" {
  name                = "${format("%s route-emitter healthy", var.env)}"
  type                = "service check"
  message             = "${format("Large portion of route-emitter unhealthy. Check deployment state. @govpaas-alerting-%s@digital.cabinet-office.gov.uk", var.aws_account)}"
  no_data_timeframe   = "7"
  require_full_window = true

  query = "${format("'http.can_connect'.over('deploy_env:%s','instance:route_emitter_debug_endpoint').by('*').last(1).pct_by_status()", var.env)}"

  thresholds {
    critical = 50
  }

  tags = ["deployment:${var.env}", "service:${var.env}_monitors", "job:route_emitter"]
}
