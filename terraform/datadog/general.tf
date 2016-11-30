resource "datadog_monitor" "disk-space" {
  name               = "${format("%s disk space", var.env)}"
  type               = "query alert"
  message            = "${format("More than {{threshold}}%% disk used. @govpaas-alerting-%s@digital.cabinet-office.gov.uk", var.aws_account)}"
  escalation_message = "There is still {{value}} % disk used. Check the VM!"
  no_data_timeframe  = "10"
  query              = "${format("max(last_5m):max:system.disk.in_use{bosh-deployment:%s,!device:/dev/loop0,!device:tmpfs,!device:cgroup,!device:udev,!device:/var/vcap/data/root_log,!device:/var/vcap/data/root_tmp,!bosh-job:concourse} by {bosh-job,device,bosh-index} * 100 > 85", var.env)}"

  thresholds {
    warning  = "75.0"
    critical = "85.0"
  }

  require_full_window = true

  tags {
    "deployment" = "${var.env}"
    "service"    = "${var.env}_monitors"
    "job"        = "all"
  }
}

resource "datadog_monitor" "concourse-disk-space" {
  name               = "${format("%s concourse disk space", var.env)}"
  type               = "query alert"
  message            = "${format("More than {{threshold}}%% disk used. @govpaas-alerting-%s@digital.cabinet-office.gov.uk", var.aws_account)}"
  escalation_message = "There is still {{value}} % disk used. Check the VM!"
  no_data_timeframe  = "30"
  query              = "${format("max(last_5m):max:system.disk.in_use{bosh-deployment:%s,!device:/dev/loop0,!device:tmpfs,!device:cgroup,!device:udev,!device:/var/vcap/data/root_log,!device:/var/vcap/data/root_tmp,bosh-job:concourse} by {bosh-job,device,bosh-index} * 100 > 97", var.env)}"

  thresholds {
    warning  = "95.0"
    critical = "97.0"
  }

  require_full_window = true

  tags {
    "deployment" = "${var.env}"
    "service"    = "${var.env}_monitors"
    "job"        = "concourse"
  }
}
