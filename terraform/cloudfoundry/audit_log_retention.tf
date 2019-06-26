variable cloudwatch_log_retention_period {
  description = "how long cloudwatch logs should be retained for (in days). Default 18 months"
  default     = 545
}

resource "aws_cloudwatch_log_group" "cc_security_events" {
  name              = "cc_security_events_${var.env}"
  retention_in_days = "${var.cloudwatch_log_retention_period}"
}

resource "aws_cloudwatch_log_group" "uaa_audit_events" {
  name              = "uaa_audit_events_${var.env}"
  retention_in_days = "${var.cloudwatch_log_retention_period}"
}
