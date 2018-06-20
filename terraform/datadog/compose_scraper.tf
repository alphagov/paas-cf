resource "datadog_monitor" "compose_host_ram_in_use" {
  name              = "${format("%s High memory utilisation on a Compose cluster host", var.env)}"
  type              = "metric alert"
  message           = "${format("Host {{host.name}} in the Compose cluster is using {{value}}%% of RAM. As this is above {{#is_alert}}{{threshold}}%%{{/is_alert}}{{#is_warning}}{{warn_threshold}}%%{{/is_warning}} the cluster may need scaling. @govpaas-alerting-%s@digital.cabinet-office.gov.uk", var.aws_account)}"
  no_data_timeframe = "20"
  notify_no_data    = true
  renotify_interval = "20"
  query             = "${format("max(last_10m):max:compose.cluster.host.ram.in_use{deployment:%s} by {host} >= 85", var.env)}"

  require_full_window = false

  tags = ["deployment:${var.env}", "service:${var.env}_monitors"]
}

resource "datadog_monitor" "compose_host_disk_in_use" {
  name              = "${format("%s High disk utilisation on a Compose cluster host", var.env)}"
  type              = "metric alert"
  message           = "${format("Host {{host.name}} in the Compose cluster is using {{value}}%% of disk. As this is above {{#is_alert}}{{threshold}}%%{{/is_alert}}{{#is_warning}}{{warn_threshold}}%%{{/is_warning}} the cluster may need scaling. @govpaas-alerting-%s@digital.cabinet-office.gov.uk", var.aws_account)}"
  no_data_timeframe = "20"
  notify_no_data    = true
  renotify_interval = "20"
  query             = "${format("max(last_10m):max:compose.cluster.host.disk.in_use{deployment:%s} by {host} >= 80", var.env)}"

  thresholds {
    warning  = "70"
    critical = "80"
  }

  require_full_window = false

  tags = ["deployment:${var.env}", "service:${var.env}_monitors"]
}
