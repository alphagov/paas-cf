resource "datadog_monitor" "queue_logsearch_redis_queue_length" {
  name                = "${format("%s Logsearch Redis queue length", var.env)}"
  type                = "metric alert"
  query               = "${format("max(last_5m):max:redis.key.length{deploy_env:%s,bosh-job:queue,key:logstash} by {host} > 1000000", var.env)}"
  message             = "${format("Logsearch Redis queue length is over {{#is_warning}}{{warn_threshold}}{{/is_warning}}{{#is_alert}}{{threshold}}, Logsearch started to drop log messages.{{/is_alert}}. See [Team Manual > Responding to alerts > Logsearch/ELK queue threshold limits](%s#logsearchelk-queue-threshold-limits) for more info. @govpaas-alerting-%s@digital.cabinet-office.gov.uk", var.datadog_documentation_url, var.aws_account)}"
  notify_no_data      = true
  require_full_window = true

  thresholds {
    critical = "1000000"
    warning  = "100000"
  }

  tags = ["deployment:${var.env}", "service:${var.env}_monitors", "job:queue"]
}
