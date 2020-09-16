#!/bin/sh

terraform state replace-provider -state="$1" -auto-approve  registry.terraform.io/-/aws registry.terraform.io/hashicorp/aws
terraform state replace-provider -state="$1" -auto-approve  registry.terraform.io/-/random registry.terraform.io/hashicorp/random
terraform state replace-provider -state="$1" -auto-approve  registry.terraform.io/-/template registry.terraform.io/hashicorp/template
