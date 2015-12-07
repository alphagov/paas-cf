variable "env" {
  description = "Environment name"
}

variable "region" {
  description = "AWS region"
  default     = "eu-west-1"
}

variable "vpc_cidr" {
  description = "CIDR for VPC"
  default     = "10.0.0.0/16"
}

variable "zones" {
  description = "AWS availability zones"
  default     = {
    zone0 = "eu-west-1a"
    zone1 = "eu-west-1b"
    zone2 = "eu-west-1c"
  }
}

variable "infra_cidrs" {
  description = "CIDR for infrastructure subnet indexed by AZ"
  default     = {
    zone0 = "10.0.0.0/24"
    zone1 = "10.0.1.0/24"
    zone2 = "10.0.2.0/24"
  }
}

variable "infra_subnet_zone_count" {
  description = "Number of zones to create infra subnet in"
  default     = 1
}

variable "office_cidrs" {
  description = "CSV of CIDR addresses for our office which will be trusted"
  default     = "80.194.77.90/32,80.194.77.100/32"
}

