resource "datadog_monitor" "invalid_tls_cert" {
  name              = "${format("%s Invalid TLS/SSL Certificate", var.env)}"
  type              = "metric alert"
  message           = "${format("{{hostname.name}} certificate {{#is_alert}}is invalid!{{/is_alert}}{{#is_warning}}expires in {{value}} days{{/is_warning}}\n\nSee [Team Manual > Responding to alerts > Invalid Certificates](%s#invalid-certificates) for more info.", var.datadog_documentation_url)}"
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

resource "datadog_monitor" "invalid_cdn_tls_cert" {
  name              = "${format("%s Invalid CloudFront TLS/SSL Certificate", var.env)}"
  type              = "metric alert"
  message           = "${format("{{hostname.name}} CloudFront certificate {{#is_alert}}is invalid!{{/is_alert}}{{#is_warning}}expires in {{value}} days{{/is_warning}}\n\nSee [Team Manual > Responding to alerts > Invalid Certificates](%s#invalid-certificates) for more info.", var.datadog_documentation_url)}"
  notify_no_data    = true
  no_data_timeframe = 240

  query = "${format("min(last_4h):min:cdn.tls.certificates.validity{deploy_env:%s} by {hostname} <= 7", var.env)}"

  require_full_window = true

  thresholds {
    warning  = 21
    critical = 7
  }

  tags = ["deployment:${var.env}", "service:${var.env}_monitors"]
}
