data "aws_cloudwatch_log_group" "cc_security_events" {
  name = "cc_security_events_${var.env}"
}

data "aws_cloudwatch_log_group" "uaa_audit_events" {
  name = "uaa_audit_events_${var.env}"
}

locals {
  destination_arn = "${replace(var.csls_kinesis_destination_arn, "REGION", var.region)}"
}

resource "aws_cloudwatch_log_subscription_filter" "cc_security_events_to_csls" {
  name            = "cc-security-events-to-csls-${var.env}"
  log_group_name  = "${data.aws_cloudwatch_log_group.cc_security_events.name}"
  destination_arn = "${local.destination_arn}"
  filter_pattern  = ""                                                         # Matches all events
  distribution    = "Random"
}

resource "aws_cloudwatch_log_subscription_filter" "uaa_audit_events_to_csls" {
  name            = "uaa-audit-events-to-csls-${var.env}"
  log_group_name  = "${data.aws_cloudwatch_log_group.uaa_audit_events.name}"
  destination_arn = "${local.destination_arn}"
  filter_pattern  = ""                                                       # Matches all events
  distribution    = "Random"
}
