provider "aws" {
  region = "${var.region}"
}

provider "aws" {
  alias  = "codecommit"
  region = "us-east-1"
}
