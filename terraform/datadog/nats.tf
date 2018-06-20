resource "datadog_monitor" "nats_process_running" {
  name                = "${format("%s NATS process running", var.env)}"
  type                = "service check"
  message             = "${format("nats process not running. Check nats state. @govpaas-alerting-%s@digital.cabinet-office.gov.uk", var.aws_account)}"
  notify_no_data      = false
  require_full_window = true

  query = "${format("'process.up'.over('deploy_env:%s','process:nats').last(4).count_by_status()", var.env)}"

  thresholds {
    ok       = 1
    warning  = 2
    critical = 3
  }

  tags = ["deployment:${var.env}", "service:${var.env}_monitors", "job:nats"]
}

resource "datadog_monitor" "nats_service_open" {
  name                = "${format("%s NATS service is accepting connections", var.env)}"
  type                = "service check"
  message             = "${format("Large portion of NATS service are not accepting connections. Check deployment state. @govpaas-alerting-%s@digital.cabinet-office.gov.uk", var.aws_account)}"
  no_data_timeframe   = "7"
  require_full_window = true

  query = "${format("'tcp.can_connect'.over('deploy_env:%s','instance:nats_server').by('*').last(1).pct_by_status()", var.env)}"

  thresholds {
    critical = 50
  }

  tags = ["deployment:${var.env}", "service:${var.env}_monitors", "job:nats"]
}

resource "datadog_monitor" "nats_cluster_service_open" {
  name                = "${format("%s NATS cluster service is accepting connections", var.env)}"
  type                = "service check"
  message             = "${format("Large portion of NATS cluster service are not accepting connections. Check deployment state. @govpaas-alerting-%s@digital.cabinet-office.gov.uk", var.aws_account)}"
  no_data_timeframe   = "7"
  require_full_window = true

  query = "${format("'tcp.can_connect'.over('deploy_env:%s','instance:nats_cluster').by('*').last(1).pct_by_status()", var.env)}"

  thresholds {
    critical = 50
  }

  tags = ["deployment:${var.env}", "service:${var.env}_monitors", "job:nats"]
}
