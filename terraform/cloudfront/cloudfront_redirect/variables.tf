variable "aliases" {
  description = "List of aliases to be registered for a new CloudFront distribution."
  type        = "list"
}

variable "env" {
  description = "DEPLOY_ENV to be used for certificates and terraform state."
}

variable "name" {
  description = "The name, to easily identify the instance. Not widely used."
}

variable "redirect_target" {
  description = "Url to redirect to"
}

variable "dns_zone_id" {
  description = "Zone ID for the system domain registered with Route 53."
}

variable "domain_cert_id" {
  description = "The ID of the certificate to be assigned to a new subdomain."
}
