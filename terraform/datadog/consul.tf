resource "datadog_monitor" "consul" {
  name               = "${format("%s Consul process running", var.env)}"
  type               = "service check"
  message            = "${format("Consul process not running on this host in environment {{host.environment}}. @govpaas-alerting-%s@digital.cabinet-office.gov.uk", var.aws_account)}"
  escalation_message = "Consul process not running! Check VM state."
  notify_no_data     = false
  query              = "${format("'process.up'.over('deploy_env:%s','process:consul').last(6).count_by_status()", var.env)}"

  thresholds {
    ok       = 1
    warning  = 3
    critical = 5
  }

  require_full_window = true

  tags = ["deployment:${var.env}", "service:${var.env}_monitors", "job:consul"]
}

resource "datadog_monitor" "consul_connect_to_port" {
  name                = "${format("%s consul cluster service is accepting connections", var.env)}"
  type                = "service check"
  message             = "Large portion of consul service are not accepting connections. Check deployment state."
  escalation_message  = "Large portion of consul service are still not accepting connections. Check deployment state."
  no_data_timeframe   = "7"
  require_full_window = true

  query = "${format("'tcp.can_connect'.over('deploy_env:%s','instance:consul_server').by('*').last(1).pct_by_status()", var.env)}"

  thresholds {
    critical = 50
  }

  tags = ["deployment:${var.env}", "service:${var.env}_monitors", "job:consul"]
}
