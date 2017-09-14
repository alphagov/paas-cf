variable "job_instances" {
  description = "List of pairs <job_name>:<job_count> of expected bosh job instance count"
  default     = []
}

variable "support_email" {
  description = "DeskPro email address"
  default     = "govpaas-alerting-dev@digital.cabinet-office.gov.uk"
}

variable "enable_compose_scraper" {
  description = "Enable Compose scraper. 1 to enable, 0 to disable."
  default     = 0
}

variable "enable_pagerduty_notifications" {
  description = "Selector to enable/disable the pagerduty notifications."
  default     = 0
}

variable "datadog_notification_24x7" {
  description = "Datadog notification for 24x7 alerts: empty string for no notification, email address (start with @) or pagerduty service name (start with @)"
}

variable "datadog_notification_in_hours" {
  description = "Datadog notification for in hours alerts: empty string for no notification, email address (start with @) or pagerduty service name (start with @)"
}

variable "datadog_documentation_url" {
  description = "URL that documents how to respond to specific DataDog alerts. Anchors can be appended to refer to specific alerts."
  default     = "https://government-paas-team-manual.readthedocs.io/en/latest/support/responding_to_alerts/"
}
