variable "vpc_id" {
  type        = string
  description = "The ID of the VPC in which the endpoint will be used."
}

variable "vpc_endpoint" {
  type        = string
  description = "The service name, in the form com.amazonaws.region.service for AWS services."
}

variable "subnet_ids" {
  type        = list(string)
  description = "The ID of one or more subnets in which to create a network interface for the endpoint."
}

variable "security_group_name" {
  type        = string
  description = "The security group to allow access to the PSN VPC Endpoint."
}

output "psn_security_group_seed_json" {
  value = "[]"
}