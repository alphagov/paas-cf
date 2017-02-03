variable "job_instances" {
  description = "List of pairs <job_name>:<job_count> of expected bosh job instance count"
  default     = []
}

variable "support_email" {
  description = "DeskPro email address"
  default     = "govpaas-alerting-dev@digital.cabinet-office.gov.uk"
}

variable "enable_cve_monitor" {
  description = "Enable CVE monitor: 1 to enable, 0 to disable"
  default     = 0
}

variable "enable_pagerduty_notifications" {
  description = "Selector to enable/disable the pagerduty notifications."
  default     = 0
}
