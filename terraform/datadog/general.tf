resource "datadog_monitor" "disk-space" {
  name           = "${format("%s disk space", var.env)}"
  type           = "query alert"
  message        = "${format("More than {{threshold}}%% disk used. @govpaas-alerting-%s@digital.cabinet-office.gov.uk", var.aws_account)}"
  notify_no_data = false
  query          = "${format("max(last_5m):max:system.disk.in_use{deploy_env:%s,!device:/dev/loop0,!device:tmpfs,!device:cgroup,!device:udev,!device:/var/vcap/data/root_log,!device:/var/vcap/data/root_tmp} by {bosh-job,device,bosh-index} * 100 > 85", var.env)}"

  thresholds {
    warning  = "75.0"
    critical = "85.0"
  }

  require_full_window = true

  tags = ["deployment:${var.env}", "service:${var.env}_monitors", "job:all"]
}

resource "datadog_monitor" "vm-swap-utilisation" {
  name  = "${format("%s VM swap utilisation", var.env)}"
  type  = "metric alert"
  query = "${format("avg(last_30m):100 - 100 * avg:system.swap.pct_free{deploy_env:%s} by {bosh-job,bosh-index} >= 25", var.env)}"

  message             = "${format("{{bosh-job.name}}/{{bosh-index.name}} swap was {{#is_warning}}{{warn_threshold}}{{/is_warning}}{{#is_alert}}{{threshold}}{{/is_alert}}%% utilised over 30m @govpaas-alerting-%s@digital.cabinet-office.gov.uk", var.aws_account)}"
  notify_no_data      = false
  require_full_window = false

  thresholds {
    critical = "25"
  }

  tags = ["deployment:${var.env}", "service:${var.env}_monitors", "job:all"]
}
