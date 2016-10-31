resource "datadog_monitor" "cell-available-memory" {
  name = "${format("%s cell available memory", var.env)}"
  type = "query alert"
  message = "${format("Less than {{threshold}}%% memory free on cells. There is only {{value}} %% memory free on average on cells. Review if this is temporary or we really need to scale... @govpaas-alerting-%s@digital.cabinet-office.gov.uk", var.aws_account)}"
  escalation_message = "There is only {{value}} % memory free on average on cells. Check the deployment!"
  no_data_timeframe = "5"
  query = "${format("avg(last_1m):avg:system.mem.pct_usable{bosh-job:cell,bosh-deployment:%s} * 100 < 50", var.env)}"

  thresholds {
    warning = "55.0"
    critical = "50.0"
  }

  require_full_window = true
  tags {
    "deployment" = "${var.env}"
    "job" = "cell"
  }
}
