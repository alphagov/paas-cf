variable "vpc_id" {
  description = "ID of VPC created in main 'vpc' terraform"
}

variable "region" {
  description = "AWS region"
}

variable "az" {
  description = "The Availability Zone that we will be hand managing"
}
