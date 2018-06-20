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
