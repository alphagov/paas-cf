terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>5.84.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~>3.5.1"
    }
    pingdom = {
      source  = "russellcardullo/pingdom"
      version = "1.1.2"
    }
  }
  required_version = ">= 1.5.2"
}
