variable "concourse_security_group_id" {
  description = "id of the security group for the concourse VM which deploys bosh with bosh-init"
}

variable "secrets_bosh_db_master_password" {
  description = "Master password for bosh database"
  # FIXME
  default = "changeme"
}

variable "bosh_db_multi_az" {
  description = "BOSH database multi availabiliy zones"
  default = "false"
}

variable "bosh_db_backup_retention_period" {
  description = "BOSH database backup retention period"
  default = 0
}
