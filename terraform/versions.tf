terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>3.61.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~>3.1.0"
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
  required_version = ">= 1.0.8"
}
