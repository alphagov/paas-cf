variable "vpc_id" {
  description = "id of VPC created in main 'vpc' terraform"
}

variable "subnet0_id" {
  description = "id of subnet0 created in main 'vpc' terraform"
}

# Terraform currently only has limited support for reading environment variables
# Variables for use with terraform must be prefexed with 'TF_VAR_'
# These two variables are passed in as environment variables named:
# TF_VAR_AWS_ACCESS_KEY_ID and TF_VAR_AWS_SECRET_ACCESS_KEY respectively
variable "AWS_ACCESS_KEY_ID" {
  description = "AWS access key to be pass to the bosh CPI"
}

variable "AWS_SECRET_ACCESS_KEY" {
  description = "AWS secret access key to be pass to the bosh CPI"
}

# TODO: Implement a way to upload ssh keys
variable "key_pair_name" {
  description = "SSH Key Pair name to be used to launch EC2 instances"
  default     = "insecure-deployer"
}

