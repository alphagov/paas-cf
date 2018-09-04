resource "datadog_monitor" "doppler_dropped_envelopes" {
  name    = "${format("%s Doppler - dropped envelopes", var.env)}"
  type    = "query alert"
  message = "${format("{{#is_alert}}A Doppler VM is dropping >= {{threshold}} envelopes.{{/is_alert}} \n{{#is_warning}}A Doppler VM is dropping >= {{warn_threshold}} envelopes.{{/is_warning}} \n\nInvestigate whether this is a one-off or we need to scale our Dopplers. @govpaas-alerting-%s@digital.cabinet-office.gov.uk", var.aws_account)}"

  query = "${format("change(max(last_10m),last_1h):max:cf.loggregator.doppler.dropped{deployment:%s} by {index} > 1000", var.env)}"

  require_full_window = false
  notify_no_data      = false

  thresholds {
    warning  = 100
    critical = 1000
  }

  tags = ["deployment:${var.env}", "service:${var.env}_monitors", "job:doppler"]
}
