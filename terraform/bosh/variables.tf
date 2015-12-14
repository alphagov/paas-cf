variable "vpc_id" {
  description = "id of VPC created in main 'vpc' terraform"
}

variable "subnet0_id" {
  description = "id of subnet0 created in main 'vpc' terraform"
}

# TODO: Implement a way to upload ssh keys
variable "key_pair_name" {
  description = "SSH Key Pair name to be used to launch EC2 instances"
  default     = "insecure-deployer"
}

