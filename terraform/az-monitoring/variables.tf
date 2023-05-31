variable "region" {
  description = "AWS region"
}
variable "enabled" {
  description = "Enable monitoring"
  default     = false
}

variable "wait_for_healthcheck" {
  description = "Wait for the healthchecks"
  default     = true
}
