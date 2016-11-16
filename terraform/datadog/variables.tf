variable "enable_cve_notifier" {
  description = "Enable CVE notifier. 1 to enable, 0 to disable."
  default     = 0
}

variable "job_instances" {
  description = "List of pairs <job_name>:<job_count> of expected bosh job instance count"
  default     = []
}
