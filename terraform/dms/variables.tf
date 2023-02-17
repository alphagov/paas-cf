variable "dms_data" {
  type = list(object({
    name               = string
    source_secret_name = string
    target_secret_name = string
    instance = object({
      allocated_storage            = number
      allow_major_version_upgrade  = bool
      apply_immediately            = bool
      auto_minor_version_upgrade   = bool
      availability_zone            = string
      engine_version               = string
      multi_az                     = bool
      preferred_maintenance_window = string
      publicly_accessible          = bool
      replication_instance_class   = string
    })
    task = optional(object({
      migration_type = optional(string)
      settings_overrides = optional(map(any))
      table_mappings = optional(map(any))
    }))
    vpc_peering = optional(object({
      cidr_block                = optional(string)
      vpc_peering_connection_id = optional(string)
    }))
  }))
  default = []
}

variable "dms_cidrs" {
  description = "CIDR list of AWS DMS subnets"
  default     = ["10.0.80.0/22", "10.0.84.0/22", "10.0.88.0/22"]
}

variable "dms_secrets_manager_role_name" {
  description = "The name of the IAM role used by dms"

  default = "dms-secrets-access"
}
