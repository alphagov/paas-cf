variable "region" {
  description = "AWS region"
}

provider "aws" {
  region = "${var.region}"
}
