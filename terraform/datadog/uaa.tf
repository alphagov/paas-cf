resource "datadog_monitor" "user_not_found" {
  name    = "${format("%s UAA - Failed login: user not found", var.env)}"
  type    = "query alert"
  message = "${format("Anomalous levels of authentication attempts with a user name that does not exist. See https://government-paas-team-manual.readthedocs.io/en/latest/support/responding_to_alerts/. @govpaas-alerting-%s@digital.cabinet-office.gov.uk", var.aws_account)}"

  query = "${format("avg(last_30m):anomalies(sum:cf.uaa.audit_service.user_not_found_count{deployment:%s}, 'agile', 2, direction='above') >= 0.5", var.env)}"

  require_full_window = true

  tags = ["deployment:${var.env}", "service:${var.env}_monitors", "job:uaa"]
}

resource "datadog_monitor" "login_with_wrong_password" {
  name    = "${format("%s UAA - Failed login: wrong password", var.env)}"
  type    = "query alert"
  message = "${format("Anomalous levels of authentication attempts with an existing user name and wrong password. See https://government-paas-team-manual.readthedocs.io/en/latest/support/responding_to_alerts/ @govpaas-alerting-%s@digital.cabinet-office.gov.uk", var.aws_account)}"

  query = "${format("avg(last_30m):anomalies(sum:cf.uaa.audit_service.user_authentication_failure_count{deployment:%s}, 'agile', 2, direction='above') >= 0.5", var.env)}"

  require_full_window = true

  tags = ["deployment:${var.env}", "service:${var.env}_monitors", "job:uaa"]
}
