variable "subnet0_id" {
  description = "id of subnet0 created in main 'vpc' terraform"
}

variable "concourse_security_group_id" {
  description = "id of the security group for the concourse VM which deploys bosh with bosh-init"
}

