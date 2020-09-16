terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>2.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~>2.3"
    }
    template = {
      source  = "hashicorp/template"
      version = "2.1.2"
    }
    pingdom = {
      source  = "russellcardullo/pingdom"
      version = "1.1.2"
    }
  }
  required_version = ">= 0.13"
}
