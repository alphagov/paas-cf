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
