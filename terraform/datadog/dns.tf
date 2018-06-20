resource "datadog_monitor" "dns_can_resolve" {
  name    = "${format("%s DNS resolution working", var.env)}"
  type    = "service check"
  message = "${format("DNS resolution is failing on {{host.name}} @govpaas-alerting-%s@digital.cabinet-office.gov.uk", var.aws_account)}"

  query = "${format("'dns.can_resolve'.over('deploy_env:%s').by('bosh-job','bosh-index').last(4).count_by_status()", var.env)}"

  thresholds {
    warning  = 1
    critical = 3
  }

  tags = ["deployment:${var.env}", "service:${var.env}_monitors"]
}

resource "datadog_monitor" "dns_response_time" {
  name                = "${format("%s DNS resolution response time", var.env)}"
  type                = "metric alert"
  message             = "DNS resolution is slow on {{host.name}}"
  notify_no_data      = false
  require_full_window = true

  query = "${format("avg(last_5m):max:dns.response_time{deploy_env:%s} by {bosh-job,bosh-index} > 0.2", var.env)}"

  thresholds {
    warning  = 0.1
    critical = 0.2
  }

  tags = ["deployment:${var.env}", "service:${var.env}_monitors"]
}
