terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>5.9.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~>3.6.3"
    }
    pingdom = {
      source  = "russellcardullo/pingdom"
      version = "1.1.2"
    }
  }
  required_version = ">= 1.5.2"
}
