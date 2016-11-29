variable "bosh_lite_region" {
  description = "AWS region where we will install bosh-lite"
  default     = "eu-west-1"
}

variable "bosh_lite_zones" {
  description = "AWS availability zones for bosh-lite"

  default = {
    zone0 = "eu-west-1a"
  }
}

variable "bosh_lite_vpc_cidr" {
  description = "CIDR for VPC"
  default     = "10.244.0.0/16"
}

variable "bosh_lite_cidrs" {
  description = "CIDR for bosh-lite subnet indexed by AZ"

  default = {
    zone0 = "10.244.0.32/28"
  }
}

variable "bosh_lite_ssh_key" {
  description = "SSH Public key for bosh lite"
}
