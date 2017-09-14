resource "datadog_monitor" "compose_scraper" {
  count              = "${var.enable_compose_scraper}"
  name               = "${format("%s compose-scraper", var.env)}"
  type               = "service check"
  message            = "${format("{{#is_alert}} No data from compose-scraper. Check the compose-scraper application in org admin space monitoring, account: %s. It should be up and running. {{/is_alert}}", var.aws_account)}"
  escalation_message = "${format("{{#is_alert}} Still no data from compose-scraper. Check the compose-scraper application in org admin space monitoring, account: %s. It should be up and running. {{/is_alert}}", var.aws_account)}"
  no_data_timeframe  = "5"
  query              = "${format("'compose.scraper.ok'.over('host:compose-scraper-%s').last(1).count_by_status()", var.env)}"

  thresholds {
    warning  = "1"
    critical = "1"
  }

  require_full_window = true

  tags = ["deployment:${var.env}", "service:${var.env}_monitors"]
}

resource "datadog_monitor" "compose_host_ram_in_use" {
  count             = "${var.enable_compose_scraper}"
  name              = "${format("%s High memory utilisation on a Compose cluster host", var.env)}"
  type              = "metric alert"
  message           = "Host {{host.name}} in the Compose cluster is using {{value}}% of RAM. As this is above {{#is_alert}}{{threshold}}%{{/is_alert}}{{#is_warning}}{{warn_threshold}}%{{/is_warning}} the cluster may need scaling."
  no_data_timeframe = "20"
  query             = "${format("max(last_10m):max:compose.cluster.host.ram.in_use{deployment:%s} by {host} >= 80", var.env)}"

  thresholds {
    warning  = "70"
    critical = "80"
  }

  require_full_window = false

  tags = ["deployment:${var.env}", "service:${var.env}_monitors"]
}

resource "datadog_monitor" "compose_host_disk_in_use" {
  count             = "${var.enable_compose_scraper}"
  name              = "${format("%s High disk utilisation on a Compose cluster host", var.env)}"
  type              = "metric alert"
  message           = "Host {{host.name}} in the Compose cluster is using {{value}}% of disk. As this is above {{#is_alert}}{{threshold}}%{{/is_alert}}{{#is_warning}}{{warn_threshold}}%{{/is_warning}} the cluster may need scaling."
  no_data_timeframe = "20"
  query             = "${format("max(last_10m):max:compose.cluster.host.disk.in_use{deployment:%s} by {host} >= 80", var.env)}"

  thresholds {
    warning  = "70"
    critical = "80"
  }

  require_full_window = false

  tags = ["deployment:${var.env}", "service:${var.env}_monitors"]
}
