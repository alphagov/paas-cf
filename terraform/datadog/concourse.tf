resource "datadog_monitor" "concourse-load" {
  name           = "${format("%s concourse load", var.env)}"
  type           = "query alert"
  message        = "${format("Concourse load is too high: {{value}}. Check VM health. @govpaas-alerting-%s@digital.cabinet-office.gov.uk", var.aws_account)}"
  notify_no_data = false
  query          = "${format("max(last_1m):max:system.load.1{bosh-job:concourse,deploy_env:%s} > 200", var.env)}"

  thresholds {
    warning  = "150.0"
    critical = "200.0"
  }

  require_full_window = true

  tags = ["deployment:${var.env}", "service:${var.env}_monitors", "job:concourse"]
}
