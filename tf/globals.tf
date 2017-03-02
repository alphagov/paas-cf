variable "env" {
  description = "Environment name"
}

variable "office_cidrs" {
  description = "CSV of CIDR addresses for our office which will be trusted"
  default     = "80.194.77.90/32,80.194.77.100/32"
}

variable "ssh_user" {
  description = "Username used to ssh into VMs."
  default     = "ubuntu"
}
