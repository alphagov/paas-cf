variable "cf_cidrs" {
  description = "CIDR for cf components subnet indexed by AZ"
  default     = {
    zone0 = "10.0.10.0/24"
    zone1 = "10.0.11.0/24"
    zone2 = "10.0.12.0/24"
  }
}

variable "cell_cidrs" {
  description = "CIDR for cell subnet indexed by AZ"
  default     = {
    zone0 = "10.0.20.0/24"
    zone1 = "10.0.21.0/24"
    zone2 = "10.0.22.0/24"
  }
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
