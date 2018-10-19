variable "datadog_api_key" {}

variable "datadog_app_key" {}

variable "env" {}

variable "aws_account" {}

variable "region" {}

provider "datadog" {
  api_key = "${var.datadog_api_key}"
  app_key = "${var.datadog_app_key}"
}
