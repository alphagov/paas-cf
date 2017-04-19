resource "datadog_monitor" "ec2-cpu-credits" {
  name           = "${format("%s EC2 CPU credits", var.env)}"
  type           = "query alert"
  message        = "${format("Instance is {{#is_warning}}low on{{/is_warning}}{{#is_alert}}out of{{/is_alert}} on CPU credits and may perform badly. See: https://government-paas-team-manual.readthedocs.io/en/latest/support/responding_to_alerts/#cpu-credits @govpaas-alerting-%s@digital.cabinet-office.gov.uk", var.aws_account)}"
  notify_no_data = false
  query          = "${format("avg(last_30m):avg:aws.ec2.cpucredit_balance{deploy_env:%s} by {bosh-job,bosh-index} <= 1", var.env)}"

  thresholds {
    warning  = "20"
    critical = "1"
  }

  require_full_window = true

  tags = ["deployment:${var.env}", "service:${var.env}_monitors", "job:all"]
}
