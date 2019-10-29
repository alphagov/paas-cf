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

locals {
  destination_arn = "${replace(var.csls_kinesis_destination_arn, "REGION", var.region)}"
}

resource "aws_cloudwatch_log_subscription_filter" "cc_security_events_to_csls" {
  name            = "cc-security-events-to-csls-${var.env}"
  log_group_name  = "${aws_cloudwatch_log_group.cc_security_events.name}"
  destination_arn = "${local.destination_arn}"
  filter_pattern  = ""                                                    # Matches all events
  distribution    = "Random"
}

resource "aws_cloudwatch_log_subscription_filter" "uaa_audit_events_to_csls" {
  name            = "uaa-audit-events-to-csls-${var.env}"
  log_group_name  = "${aws_cloudwatch_log_group.uaa_audit_events.name}"
  destination_arn = "${local.destination_arn}"
  filter_pattern  = ""                                                  # Matches all events
  distribution    = "Random"
}
