variable "job_instances" {
  description = "List of pairs <job_name>:<job_count> of expected bosh job instance count"
  default     = []
}

variable "support_email" {
  description = "DeskPro email address"
  default     = "govpaas-alerting-dev@digital.cabinet-office.gov.uk"
}
