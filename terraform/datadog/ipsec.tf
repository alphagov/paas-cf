resource "datadog_monitor" "ipsec_daemon_running" {
  name                = "${format("%s racoon ipsec daemon running", var.env)}"
  type                = "service check"
  message             = "Racoon ipsec daemon not running. Check VM state."
  escalation_message  = "Racoon ipsec daemon still not running. Check the VM!"
  notify_no_data      = false
  require_full_window = false

  query = "${format("'process.up'.over('deploy_env:%s','process:racoon').by('host','process').last(2).count_by_status()", var.env)}"

  thresholds {
    ok       = 2
    warning  = 1
    critical = 2
  }

  tags = ["deployment:${var.env}", "service:${var.env}_monitors", "job:all"]
}
