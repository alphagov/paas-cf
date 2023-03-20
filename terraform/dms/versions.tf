terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>4.36.1"
    }
    utils = {
      source = "cloudposse/utils"
      version = "~>1.7.1"
    }
  }
  required_version = ">= 1.3.3"
}
