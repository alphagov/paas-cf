resource "datadog_monitor" "nats_process_running" {
  name                = "${format("%s NATS process running", var.env)}"
  type                = "service check"
  message             = "nats process not running. Check nats state."
  escalation_message  = "nats process still not running. Check nats state."
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

resource "datadog_monitor" "nats_stream_forwarded_process_running" {
  name                = "${format("%s NATS stream forwarder process running", var.env)}"
  type                = "service check"
  message             = "NATS stream forwarder process not running. Check nats state."
  escalation_message  = "NATS stream forwarder process still not running. Check NATS state."
  notify_no_data      = false
  require_full_window = true

  query = "${format("'process.up'.over('deploy_env:%s','process:nats_stream_forwarder').last(4).count_by_status()", var.env)}"

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
  message             = "Large portion of NATS service are not accepting connections. Check deployment state."
  escalation_message  = "Large portion of NATS service are still not accepting connections. Check deployment state."
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
  message             = "Large portion of NATS cluster service are not accepting connections. Check deployment state."
  escalation_message  = "Large portion of NATS cluster service are still not accepting connections. Check deployment state."
  no_data_timeframe   = "7"
  require_full_window = true

  query = "${format("'tcp.can_connect'.over('deploy_env:%s','instance:nats_cluster').by('*').last(1).pct_by_status()", var.env)}"

  thresholds {
    critical = 50
  }

  tags = ["deployment:${var.env}", "service:${var.env}_monitors", "job:nats"]
}
