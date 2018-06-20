resource "datadog_monitor" "syslog_drains" {
  name                = "${format("%s syslog drains", var.env)}"
  type                = "query alert"
  message             = "${format("Consider scaling the adapters to cope with the number of syslog drains. See https://github.com/cloudfoundry/cf-syslog-drain-release/tree/v6.4#syslog-adapter @govpaas-alerting-%s@digital.cabinet-office.gov.uk", var.aws_account)}"
  escalation_message  = "You must scale the adapter VMs to cope with the number of syslog drains. See https://github.com/cloudfoundry/cf-syslog-drain-release/tree/v6.4#syslog-adapter"
  require_full_window = true

  query = "${format("avg(last_1d):avg:cf.cf_syslog_drain.scheduler.drains{deployment:%s} > 300", var.env)}"

  thresholds {
    warning  = 250
    critical = 300
  }

  tags = ["deployment:${var.env}", "service:${var.env}_monitors", "job:adapter"]
}
