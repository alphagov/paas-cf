variable "concourse_security_group_id" {
  description = "id of the security group for the concourse VM which deploys bosh with bosh-init"
}

variable "cf_cidrs" {
  description = "CIDR for cf components subnet indexed by AZ"
  default     = {
    zone0 = "10.0.16.0/24"
    zone1 = "10.0.17.0/24"
    zone2 = "10.0.18.0/24"
  }
}

variable "cell_cidrs" {
  description = "CIDR for cell subnet indexed by AZ"
  default     = {
    zone0 = "10.0.32.0/24"
    zone1 = "10.0.33.0/24"
    zone2 = "10.0.34.0/24"
  }
}

variable "router_cidrs" {
  description = "CIDR for router subnets indexed by AZ"
  default     = {
    zone0 = "10.0.48.0/24"
    zone1 = "10.0.49.0/24"
    zone2 = "10.0.50.0/24"
  }
}

variable "cell_cidr_all" {
  description = "CIDR for all cell subnets"
  default     = "10.0.32.0/20"
}

variable "cf_cidr_all" {
  description = "CIDR for all cell subnets"
  default     = "10.0.16.0/20"
}

variable "router_cidr_all" {
  description = "CIDR for all router subnets"
  default     = "10.0.48.0/20"
}

variable "health_check_interval" {
  description = "Interval between requests for load balancer health checks"
  default     = 5
}

variable "health_check_timeout" {
  description = "Timeout of requests for load balancer health checks"
  default     = 2
}

variable "health_check_healthy" {
  description = "Threshold to consider load balancer healthy"
  default     = 2
}

variable "health_check_unhealthy" {
  description = "Threshold to consider load balancer unhealthy"
  default     = 2
}

variable "elb_idle_timeout" {
  description = "Timeout idle connections after 300 seconds"
  default     = 300
}

variable "subnet0_id" {
    description = "Subnet that is used to provision ELB"
}

variable "cf_subnet_count" {
  description = "Number of CF subnets"
  default     = 2
}

variable "concourse_elastic_ip" {
  description = "Public IP of the deployer-concourse machine"
}
