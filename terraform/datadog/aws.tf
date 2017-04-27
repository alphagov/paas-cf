resource "datadog_monitor" "ec2-cpu-credits" {
  name           = "${format("%s EC2 CPU credits", var.env)}"
  type           = "query alert"
  message        = "${format("Instance is {{#is_warning}}low on{{/is_warning}}{{#is_alert}}out of{{/is_alert}} CPU credits and may perform badly. See: %s#cpu-credits @govpaas-alerting-%s@digital.cabinet-office.gov.uk", var.datadog_documentation_url, var.aws_account)}"
  notify_no_data = false
  query          = "${format("avg(last_30m):avg:aws.ec2.cpucredit_balance{deploy_env:%s} by {bosh-job,bosh-index} <= 1", var.env)}"

  thresholds {
    warning  = "20"
    critical = "1"
  }

  require_full_window = false

  tags = ["deployment:${var.env}", "service:${var.env}_monitors", "job:all"]
}

resource "datadog_monitor" "rds-cpu-credits" {
  name           = "${format("%s RDS CPU credits", var.env)}"
  type           = "query alert"
  message        = "${format("Instance is {{#is_warning}}low on{{/is_warning}}{{#is_alert}}out of{{/is_alert}} CPU credits and may perform badly. See: %s#cpu-credits @govpaas-alerting-%s@digital.cabinet-office.gov.uk", var.datadog_documentation_url, var.aws_account)}"
  notify_no_data = false
  query          = "${format("avg(last_30m):avg:aws.rds.cpucredit_balance{deploy_env:%s,!created_by:aws_rds_service_broker} by {dbinstanceidentifier} <= 1", "master")}"

  thresholds {
    warning  = "20"
    critical = "1"
  }

  require_full_window = false

  tags = ["deployment:${var.env}", "service:${var.env}_monitors", "job:all"]
}
