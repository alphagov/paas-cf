variable "ami" {
  description = "The AMI ID to be rolled out onto the VMs"
}

variable "cidr" {
  description = "The CIDR block for the subnet to be created in"
}

variable "instance_type" {
  default     = "t3.nano"
  description = "The instance type and sizing used for the VMs"
}

variable "region" {
  description = "AWS region"
}

variable "vpc_id" {
  description = "ID of VPC created in main 'vpc' terraform"
}

variable "zone" {
  description = "The regions availability zone to spin up infrastructure in (ie: a, b, c)"
}

variable "aws_route_table_id" {
  description = "Route Table ID for association with subnets"
}
