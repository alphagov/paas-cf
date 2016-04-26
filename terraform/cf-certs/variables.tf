variable "system_domain_crt" {
  description = "Public facing system components certificate"
}

variable "system_domain_key" {
  description = "Private key of the public facing system components certificate"
}

variable "apps_domain_crt" {
  description = "Public facing apps certificate"
}

variable "apps_domain_key" {
  description = "Private key of the public facing apps certificate"
}
