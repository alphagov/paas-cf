resource "datadog_monitor" "invalid_tls_cert" {
  name              = "${format("%s Invalid TLS/SSL Certificate", var.env)}"
  type              = "metric alert"
  message           = "${format("{{hostname.name}} certificate {{#is_alert}}is invalid!{{/is_alert}}{{#is_warning}}expires in {{value}} days{{/is_warning}}\n\nSee [Team Manual > Responding to alerts > Invalid Certificates](%s#invalid-certificates) for more info. @govpaas-alerting-%s@digital.cabinet-office.gov.uk", var.datadog_documentation_url, var.aws_account)}"
  notify_no_data    = true
  no_data_timeframe = 120

  query = "${format("min(last_1h):min:tls.certificates.validity{deploy_env:%s} by {hostname} <= 7", var.env)}"

  require_full_window = true

  thresholds {
    warning  = 30
    critical = 7
  }

  tags = ["deployment:${var.env}", "service:${var.env}_monitors"]
}

resource "datadog_monitor" "cdn_tls_cert_expiry" {
  name    = "${format("%s CloudFront TLS/SSL Certificates expiry", var.env)}"
  type    = "metric alert"
  message = "${format("{{hostname.name}} CloudFront certificate {{#is_alert}}is almost expired!{{/is_alert}}{{#is_warning}}expires in {{value}} days{{/is_warning}}\n\nSee [Team Manual > Responding to alerts > Invalid Certificates](%s#invalid-certificates) for more info. @govpaas-alerting-%s@digital.cabinet-office.gov.uk", var.datadog_documentation_url, var.aws_account)}"

  query = "${format("min(last_4h):min:cdn.tls.certificates.expiry{deploy_env:%s} by {hostname} <= 7", var.env)}"

  require_full_window = false

  thresholds {
    warning  = 21
    critical = 7
  }

  tags = ["deployment:${var.env}", "service:${var.env}_monitors"]
}

resource "datadog_monitor" "cdn_tls_cert_validity" {
  name              = "${format("%s CloudFront TLS/SSL Certificate validity", var.env)}"
  type              = "metric alert"
  message           = "${format("A high number of CloudFront certificates are invalid.\n\nSee [Team Manual > Responding to alerts > Invalid Certificates](%s#invalid-certificates) for more info. @govpaas-alerting-%s@digital.cabinet-office.gov.uk", var.datadog_documentation_url, var.aws_account)}"
  notify_no_data    = true
  no_data_timeframe = 480

  query = "${format("min(last_4h):avg:cdn.tls.certificates.validity{deploy_env:%s} <= 0.75", var.env)}"

  require_full_window = false

  thresholds {
    warning  = 0.85
    critical = 0.75
  }

  tags = ["deployment:${var.env}", "service:${var.env}_monitors"]
}
