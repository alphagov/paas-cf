terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>4.36.1"
    }
    random = {
      source  = "hashicorp/random"
      version = "~>3.4.3"
    }
    pingdom = {
      source  = "russellcardullo/pingdom"
      version = "1.1.2"
    }
  }
  required_version = ">= 1.3.3"
}
