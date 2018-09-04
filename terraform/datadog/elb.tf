resource "datadog_monitor" "unhealthy_elb_node" {
  name           = "${format("%s At least one ELB node is not responding", var.env)}"
  type           = "metric alert"
  message        = "${format("Requests to the healthcheck app via {{value}} of the ELB IP addresses failed.\n\nSee [Team Manual > Responding to alerts > Intermittent ELB failures](%s#intermittent-elb-failures) for more info. @govpaas-alerting-%s@digital.cabinet-office.gov.uk", var.datadog_documentation_url, var.aws_account)}"
  notify_no_data = true

  query = "${format("min(last_1m):max:aws.elb.unhealthy_node_count{deploy_env:%s} > 0", var.env)}"

  require_full_window = true

  thresholds {
    critical = 0
  }

  tags = ["deployment:${var.env}", "service:${var.env}_monitors"]
}
