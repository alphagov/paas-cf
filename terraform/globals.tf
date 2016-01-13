variable "env" {
  description = "Environment name"
}

variable "region" {
  description = "AWS region"
  default     = "eu-west-1"
}

variable "vpc_cidr" {
  description = "CIDR for VPC"
  default     = "10.0.0.0/16"
}

variable "zones" {
  description = "AWS availability zones"
  default     = {
    zone0 = "eu-west-1a"
    zone1 = "eu-west-1b"
    zone2 = "eu-west-1c"
  }
}

variable "infra_cidrs" {
  description = "CIDR for infrastructure subnet indexed by AZ"
  default     = {
    zone0 = "10.0.0.0/24"
    zone1 = "10.0.1.0/24"
    zone2 = "10.0.2.0/24"
  }
}

variable "infra_subnet_zone_count" {
  description = "Number of zones to create infra subnet in"
  default     = 3
}

/* see https://sites.google.com/a/digital.cabinet-office.gov.uk/gds-internal-it/news/aviationhouse-sourceipaddresses for details. */
variable "office_cidrs" {
  description = "CSV of CIDR addresses for our office which will be trusted"
  default     = "80.194.77.90/32,80.194.77.100/32,85.133.67.244/32"
}

variable "vagrant_cidr" {
  description = "IP address of the AWS Vagrant bootstrap concourse"
  default     = ""
}

variable "dns_zone_id" {
  description = "Amazon Route53 DNS zone identifier"
  default     = "Z3SI0PSH6KKVH4"
}

variable "dns_zone_name" {
  description = "Amazon Route53 DNS zone name"
  default     = "cf.paas.alphagov.co.uk"
}

variable "microbosh_static_private_ip" {
  description = "Microbosh internal IP"
  default     = "10.0.0.6"
}

variable "web_access_cidrs" {
  description = "CSV of CIDR addresses for which we allow web access"
  default     = "80.194.77.90/32,80.194.77.100/32,85.133.67.244/32"
}

variable "concourse_elb_cert_arn" {
  description = "Concourse ELB certificate ARN"
  default     = "arn:aws:iam::988997429095:server-certificate/wildcard-cf-paas"
}
