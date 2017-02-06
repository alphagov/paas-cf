variable "aliases" {
  description = "List of aliases to be registered for a new CloudFront distribution."
  type        = "list"
}

variable "comment" {
  description = "Comment to describe the CloudFront distribution. Could be empty string."
}

variable "env" {
  description = "DEPLOY_ENV to be used for certificates and terraform state."
}

variable "name" {
  description = "The name, to easily identify the instance. Not widely used."
}

variable "origin" {
  description = "The origin URL to be cached into the CloudFront distribution."
}

variable "system_dns_zone_id" {
  description = "Zone ID for the system domain registered with Route 53."
}

variable "system_dns_zone_name" {
  description = "Domain name registered with Route 53."
}

variable "system_domain_cert_id" {
  description = "The ID of the certificate to be assigned to a new subdomain."
}
