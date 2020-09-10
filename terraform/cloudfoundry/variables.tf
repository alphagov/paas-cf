data "aws_caller_identity" "current" {}

variable "apps_dns_zone_id" {
  description = "Amazon Route53 DNS zone identifier for hosted apps. Different per account."
}

variable "apps_dns_zone_name" {
  description = "Amazon Route53 DNS zone name for hosted apps. Differs per account."
}

variable "apps_wildcard_canary_weight" {
  description = "Amount of traffic the wildcard canary DNS record receives"
  default     = 0
}

variable "apps_wildcard_weight" {
  description = "Amount of traffic the wildcard DNS record receives"
  default     = 100
}

variable "aws_backing_service_cidrs" {
  description = "CIDR for AWS backing service subnets indexed by AZ"

  default = {
    zone0 = "10.0.52.0/24"
    zone1 = "10.0.53.0/24"
    zone2 = "10.0.54.0/24"
    zone3 = "10.0.55.0/24"
    zone4 = "10.0.56.0/24"
    zone5 = "10.0.57.0/24"
    zone6 = "10.0.58.0/24"
    zone7 = "10.0.59.0/24"
    zone8 = "10.0.60.0/24"
  }
}

variable "cdn_db_backup_retention_period" {
  description = "CDN database backup retention period"
}

variable "cdn_db_maintenance_window" {
  description = "The window during which updates to the CDN database instance can occur."
}

variable "cdn_db_multi_az" {
  description = "CDN database multi availabiliy zones"
}

variable "cdn_db_skip_final_snapshot" {
  description = "Whether to skip final RDS snapshot (just before destroy). Differs per environment."
}

variable "cell_cidrs" {
  description = "CIDR for cell subnet indexed by AZ"

  default = {
    zone0 = "10.0.32.0/24"
    zone1 = "10.0.33.0/24"
    zone2 = "10.0.34.0/24"
  }
}

variable "cf_cidrs" {
  description = "CIDR for cf components subnet indexed by AZ"

  default = {
    zone0 = "10.0.16.0/24"
    zone1 = "10.0.17.0/24"
    zone2 = "10.0.18.0/24"
  }
}

variable "cf_db_backup_retention_period" {
  description = "CF database backup retention period"
}

variable "cf_db_instance_type" {
  description = "The instance type (e.g. db.m5.large)"
}

variable "cf_db_maintenance_window" {
  description = "The window during which updates to the CF database instance can occur."
}

variable "cf_db_multi_az" {
  description = "CF database multi availabiliy zones"
}

variable "cf_db_skip_final_snapshot" {
  description = "Whether to skip final RDS snapshot (just before destroy). Differs per environment."
}

variable "cf_subnet_count" {
  description = "Number of CF subnets"
  default     = 2
}

variable "concourse_elastic_ip" {
  description = "Public IP of the deployer-concourse machine"
}

variable "concourse_security_group_id" {
  description = "Security group ID for concourse"
}

variable "elb_idle_timeout" {
  description = "Timeout idle connections after 300 seconds"
  default     = 300
}

variable "health_check_healthy" {
  description = "Threshold to consider load balancer healthy"
  default     = 2
}

variable "health_check_interval" {
  description = "Interval between requests for load balancer health checks"
  default     = 5
}

variable "health_check_timeout" {
  description = "Timeout of requests for load balancer health checks"
  default     = 2
}

variable "health_check_unhealthy" {
  description = "Threshold to consider load balancer unhealthy"
  default     = 2
}

variable "prometheus_azs" {
  description = "Availability zones for Prometheus instances"
  default     = ["z1", "z2"]
}

variable "router_cidrs" {
  description = "CIDR for router subnets indexed by AZ"

  default = {
    zone0 = "10.0.48.0/24"
    zone1 = "10.0.49.0/24"
    zone2 = "10.0.50.0/24"
  }
}

variable "secrets_cdn_db_master_password" {
  description = "Master password for CDN database"
}

variable "secrets_cf_db_master_password" {
  description = "Master password for CF database"
}

variable "system_dns_zone_id" {
  description = "Amazon Route53 DNS zone identifier for the system components. Different per account."
}

variable "system_dns_zone_name" {
  description = "Amazon Route53 DNS zone name for the provisioned environment."
}
