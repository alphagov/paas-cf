resource "datadog_monitor" "cve-reporter" {
  count = "${var.enable_cve_monitor}"

  name    = "${format("%s New CVE Reported", var.env)}"
  type    = "event alert"
  message = "${format("{{#is_alert}}Check https://government-paas-team-manual.readthedocs.io/en/latest/team/responding_to_security_issues/ for instructions @%s{{/is_alert}}", var.support_email)}"
  query   = "events('sources:feed priority:all status:info tags:cve,service:pivotal').rollup('count').last('5m') >= 1"

  thresholds {
    ok       = "1"
    warning  = "1"
    critical = "1"
  }

  tags = ["deployment:${var.env}", "service:${var.env}_monitors"]
}
