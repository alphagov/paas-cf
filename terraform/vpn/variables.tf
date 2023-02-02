variable "vpn_data" {
  type = list(object({
    name = optional(string)
    aws_customer_gateway = optional(object({
      bgp_asn    = number
      ip_address = string
      type       = optional(string, "ipsec.1")
    }))
    aws_vpn_connection = optional(object({
      type                     = optional(string, "ipsec.1")
      tunnel_inside_ip_version = optional(string, "ipv4")
      destination_cidr_blocks  = list(string)
    }))
  }))
  default = []
}

variable "vpn_key_data" {
  type    = map(any)
  default = {}
}

variable "aws_backing_service_cidrs" {
  description = "CIDR for AWS backing service subnets indexed by AZ"

  default = {
    zone0  = "10.0.52.0/24"
    zone1  = "10.0.53.0/24"
    zone2  = "10.0.54.0/24"
    zone3  = "10.0.55.0/24"
    zone4  = "10.0.56.0/24"
    zone5  = "10.0.57.0/24"
    zone6  = "10.0.58.0/24"
    zone7  = "10.0.59.0/24"
    zone8  = "10.0.60.0/24"
    zone9  = "10.0.61.0/24"
    zone10 = "10.0.62.0/24"
    zone11 = "10.0.63.0/24"
  }
}
