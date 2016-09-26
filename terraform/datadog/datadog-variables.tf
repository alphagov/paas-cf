variable "datadog_api_key" {}
variable "datadog_app_key" {}
variable "env" {}

# Work around https://github.com/hashicorp/terraform/issues/4084
data "null_data_source" "datadog" {
  inputs = {
    env = "${replace(var.env, "-", "_")}"
  }
}
