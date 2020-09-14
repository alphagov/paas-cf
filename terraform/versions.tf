terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
    random = {
      source = "hashicorp/random"
    }
    template = {
      source = "hashicorp/template"
    }
    pingdom = {
        source = "registry.terraform.io/providers/russellcardullo/pingdom"
    }
  }
  required_version = ">= 0.13"
}
