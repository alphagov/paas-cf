resource "datadog_monitor" "cc_api_master_process_running" {
  name                = "${format("%s Cloud Controller API master process running", var.env)}"
  type                = "service check"
  message             = "${format("Cloud Controller API master process is not running. Check deployment state. @govpaas-alerting-%s@digital.cabinet-office.gov.uk", var.aws_account)}"
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
  message             = "${format("Cloud Controller API worker process is not running. Check deployment state. @govpaas-alerting-%s@digital.cabinet-office.gov.uk", var.aws_account)}"
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
  message             = "${format("Large portion of Cloud Controller API master unhealthy. Check deployment state. @govpaas-alerting-%s@digital.cabinet-office.gov.uk", var.aws_account)}"
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
  message             = "${format("Amount of failed jobs in Cloud Controller API grew considerably. See logit.io: '@source.component:cloud_controller_worker AND @level:ERROR' {{#is_alert}}%s{{/is_alert}} @govpaas-alerting-%s@digital.cabinet-office.gov.uk", var.datadog_notification_in_hours, var.aws_account)}"
  require_full_window = false

  query = "${format("change(max(last_1m),last_30m):max:cf.cc.failed_job_count.total{deployment:%s}.rollup(avg, 30) > 5", var.env)}"

  thresholds {
    warning  = "3"
    critical = "5"
  }

  tags = ["deployment:${var.env}", "service:${var.env}_monitors", "job:api"]
}

resource "datadog_monitor" "cc_log_count_error_increase" {
  name    = "${format("%s Cloud Controller API log error count", var.env)}"
  type    = "query alert"
  message = "${format("Amount of logged errors in Cloud Controller API grew considerably. See logit.io: '@source.component:cloud_controller_ng AND @level:ERROR' {{#is_alert}}%s{{/is_alert}} @govpaas-alerting-%s@digital.cabinet-office.gov.uk", var.datadog_notification_in_hours, var.aws_account)}"

  query               = "${format("avg(last_30m):anomalies(sum:cf.cc.log_count.error{deployment:%s}, 'agile', 2, direction='above') >= 0.5", var.env)}"
  require_full_window = true

  tags = ["deployment:${var.env}", "service:${var.env}_monitors", "job:api"]
}

resource "datadog_monitor" "cc_job_queue_length" {
  name                = "${format("%s Cloud Controller API job queue length", var.env)}"
  type                = "query alert"
  message             = "${format("Job queue in Cloud Controller API grew considerably, check the API health. @govpaas-alerting-%s@digital.cabinet-office.gov.uk", var.aws_account)}"
  require_full_window = false

  query = "${format("avg(last_30m):max:cf.cc.job_queue_length.total{deployment:%s} > 25", var.env)}"

  thresholds {
    warning  = "20"
    critical = "25"
  }

  tags = ["deployment:${var.env}", "service:${var.env}_monitors", "job:api"]
}

resource "datadog_monitor" "cc_gorouter_latency" {
  name                = "${format("%s Cloud Controller latency as reported by gorouter", var.env)}"
  type                = "query alert"
  message             = "${format("Average latency of cloud controller calls is high - this may be due to a high proportion of expensive API calls or it may indicate that the API servers need to be scaled up @govpaas-alerting-%s@digital.cabinet-office.gov.uk", var.aws_account)}"
  require_full_window = false

  query = "${format("avg(last_10m):avg:cf.gorouter.latency.CloudController{deployment:%s} > 250", var.env)}"

  thresholds {
    warning  = "200"
    critical = "250"
  }

  tags = ["deployment:${var.env}", "service:${var.env}_monitors", "job:api"]
}

resource "datadog_monitor" "cc_gorouter_unregistry" {
  name                = "${format("%s Cloud Controller is unregistering from gorouter", var.env)}"
  type                = "query alert"
  message             = "${format("Cloud Controller is unregistering from gorouter, this probably means it is failing its route_registrar healthcheck. This could be due to high load, and may indicate that the API servers need to be scaled up @govpaas-alerting-%s@digital.cabinet-office.gov.uk", var.aws_account)}"
  require_full_window = false

  query = "${format("max(last_10m):per_hour(avg:cf.gorouter.unregistry_message.CloudController{deployment:%s}) > 10", var.env)}"

  thresholds {
    warning  = "5"
    critical = "10"
  }

  tags = ["deployment:${var.env}", "service:${var.env}_monitors", "job:api"]
}
