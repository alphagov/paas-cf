resource "datadog_monitor" "Bosh-dns" {
  name           = "${format("%s Bosh-dns process running", var.env)}"
  type           = "service check"
  message        = "${format("Bosh-dns process not running on this host in environment {{host.environment}}. @govpaas-alerting-%s@digital.cabinet-office.gov.uk", var.aws_account)}"
  notify_no_data = false
  query          = "${format("'process.up'.over('deploy_env:%s','process:bosh-dns').by('host','process').last(6).count_by_status()", var.env)}"

  thresholds {
    ok       = 1
    warning  = 3
    critical = 5
  }

  require_full_window = true

  tags = ["deployment:${var.env}", "service:${var.env}_monitors", "job:bosh_dns"]
}
