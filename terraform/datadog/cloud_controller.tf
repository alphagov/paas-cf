resource "datadog_monitor" "cc_api_master_process_running" {
  name                = "${format("%s Cloud Controller API master process running", var.env)}"
  type                = "service check"
  message             = "Cloud Controller API master process is not running. Check deployment state."
  escalation_message  = "Cloud Controller API master process is still not running. Check deployment state."
  notify_no_data      = false
  require_full_window = true

  query = "${format("'process.up'.over('bosh-deployment:%s','process:cc_api_master').last(4).count_by_status()", var.env)}"

  thresholds {
    ok       = 1
    warning  = 2
    critical = 3
  }

  tags {
    "deployment" = "${var.env}"
    "service"    = "${var.env}_monitors"
    "job"        = "api"
  }
}

resource "datadog_monitor" "cc_api_worker_process_running" {
  name                = "${format("%s Cloud Controller API worker process running", var.env)}"
  type                = "service check"
  message             = "Cloud Controller API worker process is not running. Check deployment state."
  escalation_message  = "Cloud Controller API worker process is still not running. Check deployment state."
  notify_no_data      = false
  require_full_window = true

  query = "${format("'process.up'.over('bosh-deployment:%s','process:cc_api_worker').last(4).count_by_status()", var.env)}"

  thresholds {
    ok       = 1
    warning  = 2
    critical = 3
  }

  tags {
    "deployment" = "${var.env}"
    "service"    = "${var.env}_monitors"
    "job"        = "api"
  }
}

resource "datadog_monitor" "cc_api_healthy" {
  name                = "${format("%s Cloud Controller API healthy", var.env)}"
  type                = "service check"
  message             = "Large portion of Cloud Controller API master unhealthy. Check deployment state."
  escalation_message  = "Large portion of Cloud Controller API master still unhealthy. Check deployment state."
  no_data_timeframe   = "7"
  require_full_window = true

  query = "${format("'http.can_connect'.over('bosh-deployment:%s','instance:cc_endpoint').by('*').last(1).pct_by_status()", var.env)}"

  thresholds {
    critical = 50
  }

  tags {
    "deployment" = "${var.env}"
    "service"    = "${var.env}_monitors"
    "job"        = "api"
  }
}
