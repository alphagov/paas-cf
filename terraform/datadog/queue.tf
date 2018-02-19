resource "datadog_monitor" "queue_logsearch_redis_queue_length" {
  name                = "${format("%s Logsearch Redis queue length", var.env)}"
  type                = "metric alert"
  query               = "${format("max(last_5m):avg:redis.key.length{deploy_env:%s,bosh-job:queue,key:logstash} > 1000000", var.env)}"
  message             = "Logsearch Redis queue length is over {{#is_warning}}{{warn_threshold}}{{/is_warning}}{{#is_alert}}{{threshold}}, Logsearch started to drop log messages.{{/is_alert}}. Please check whether all components of Logsearch functions properly."
  notify_no_data      = true
  require_full_window = true

  thresholds {
    critical = "1000000"
    warning  = "100000"
  }

  tags = ["deployment:${var.env}", "service:${var.env}_monitors", "job:queue"]
}
