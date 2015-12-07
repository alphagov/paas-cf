variable "concourse_db_password" {
  description = "Concourse database password"
}

variable "vpc_id" {
  description = "id of VPC created in main 'vpc' terraform"
}

variable "subnet0_id" {
  description = "id of subnet0 created in main 'vpc' terraform"
}

variable "subnet1_id" {
  description = "id of subnet1 created in main 'vpc' terraform"
}

variable "subnet2_id" {
  description = "id of subnet2 created in main 'vpc' terraform"
}
