variable "vpc_peers" {
  type = list(object({
    peer_name   = string
    account_id  = string
    vpc_id      = string
    subnet_cidr = string
  }))
  default = []
  validation {
    condition     = alltrue([for peer in var.vpc_peers : length(regexall("^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])(\\/(3[0-2]|[1-2][0-9]|[0-9]))$", peer.subnet_cidr)) > 0])
    error_message = "A valid CIDR range is required."
  }
}
