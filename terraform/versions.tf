terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>4.15.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~>3.2.0"
    }
    template = {
      source  = "hashicorp/template"
      version = "2.2.0"
    }
    pingdom = {
      source  = "russellcardullo/pingdom"
      version = "1.1.2"
    }
  }
  required_version = ">= 1.2.0"
}
