terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>5.59.0"
    }
    utils = {
      source = "cloudposse/utils"
      version = "~>1.24.0"
    }
  }
  required_version = ">= 1.9.2"
}
