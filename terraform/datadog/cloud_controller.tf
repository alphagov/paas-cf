resource "datadog_monitor" "cc_api_master_process_running" {
  name                = "${format("%s Cloud Controller API master process running", var.env)}"
  type                = "service check"
  message             = "Cloud Controller API master process is not running. Check deployment state."
  escalation_message  = "Cloud Controller API master process is still not running. Check deployment state."
  notify_no_data      = false
  require_full_window = true

  query = "${format("'process.up'.over('deploy_env:%s','process:cc_api_master').last(4).count_by_status()", var.env)}"

  thresholds {
    ok       = 1
    warning  = 2
    critical = 3
  }

  tags = ["deployment:${var.env}", "service:${var.env}_monitors", "job:api"]
}

resource "datadog_monitor" "cc_api_worker_process_running" {
  name                = "${format("%s Cloud Controller API worker process running", var.env)}"
  type                = "service check"
  message             = "Cloud Controller API worker process is not running. Check deployment state."
  escalation_message  = "Cloud Controller API worker process is still not running. Check deployment state."
  notify_no_data      = false
  require_full_window = true

  query = "${format("'process.up'.over('deploy_env:%s','process:cc_api_worker').last(4).count_by_status()", var.env)}"

  thresholds {
    ok       = 1
    warning  = 2
    critical = 3
  }

  tags = ["deployment:${var.env}", "service:${var.env}_monitors", "job:api"]
}

resource "datadog_monitor" "cc_api_healthy" {
  name                = "${format("%s Cloud Controller API healthy", var.env)}"
  type                = "service check"
  message             = "Large portion of Cloud Controller API master unhealthy. Check deployment state."
  escalation_message  = "Large portion of Cloud Controller API master still unhealthy. Check deployment state."
  no_data_timeframe   = "7"
  require_full_window = true

  query = "${format("'http.can_connect'.over('deploy_env:%s','instance:cc_endpoint').by('*').last(1).pct_by_status()", var.env)}"

  thresholds {
    critical = 50
  }

  tags = ["deployment:${var.env}", "service:${var.env}_monitors", "job:api"]
}

resource "datadog_monitor" "cc_failed_job_count_total_increase" {
  name                = "${format("%s Cloud Controller API failed job count", var.env)}"
  type                = "query alert"
  message             = "Amount of failed jobs in Cloud Controller API grew considerably, check the API health."
  escalation_message  = "Amount of failed jobs in Cloud Controller API still growing considerably, check the API health."
  require_full_window = false

  query = "${format("change(max(last_1m),last_30m):max:cf.cc.failed_job_count.total{deployment:%s} > 5", var.env)}"

  thresholds {
    warning  = "3"
    critical = "5"
  }

  tags = ["deployment:${var.env}", "service:${var.env}_monitors", "job:api"]
}

resource "datadog_monitor" "cc_log_count_error_increase" {
  name                = "${format("%s Cloud Controller API log error count", var.env)}"
  type                = "query alert"
  message             = "Amount of logged errors in Cloud Controller API grew considerably, check the API health."
  escalation_message  = "Amount of logged errors in Cloud Controller API still growing considerably, check the API health."
  require_full_window = false

  query = "${format("change(max(last_1m),last_30m):sum:cf.cc.log_count.error{deployment:%s} > 5", var.env)}"

  thresholds {
    warning  = "3"
    critical = "5"
  }

  tags = ["deployment:${var.env}", "service:${var.env}_monitors", "job:api"]
}

resource "datadog_monitor" "cc_job_queue_length" {
  name                = "${format("%s Cloud Controller API job queue length", var.env)}"
  type                = "query alert"
  message             = "Job queue in Cloud Controller API grew considerably, check the API health."
  escalation_message  = "Job queue in Cloud Controller API still too big, check the API health."
  require_full_window = false

  query = "${format("avg(last_30m):max:cf.cc.job_queue_length.total{deployment:%s} > 25", var.env)}"

  thresholds {
    warning  = "20"
    critical = "25"
  }

  tags = ["deployment:${var.env}", "service:${var.env}_monitors", "job:api"]
}
