variable "aws_account" {
  description = "the AWS account being deployed to"
}

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

variable "vpc_id" {
  description = "id of VPC created in main 'vpc' terraform"
  default     = ""
}

variable "zones" {
  description = "AWS availability zones"
  default     = {
    zone0 = "eu-west-1a"
    zone1 = "eu-west-1b"
    zone2 = "eu-west-1c"
  }
}

variable "zone_count" {
  description = "Number of zones to use"
  default = 2
}

variable "infra_cidrs" {
  description = "CIDR for infrastructure subnet indexed by AZ"
  default     = {
    zone0 = "10.0.0.0/24"
    zone1 = "10.0.1.0/24"
    zone2 = "10.0.2.0/24"
  }
}

variable "infra_cidr_all" {
  description = "CIDR for all infrastructure subnets"
  default     = "10.0.0.0/20"
}

variable "infra_subnet_ids" {
  description = "A comma separated list of infrastructure subnets"
  default     = ""
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

variable "system_dns_zone_id" {
  description = "Amazon Route53 DNS zone identifier for the system components. Different per account."
}

variable "system_dns_zone_name" {
  description = "Amazon Route53 DNS zone name for the system components. Differs per account."
}

variable "apps_dns_zone_id" {
  description = "Amazon Route53 DNS zone identifier for hosted apps. Different per account."
}

variable "apps_dns_zone_name" {
  description = "Amazon Route53 DNS zone name for hosted apps. Differs per account."
}

variable "microbosh_static_private_ip" {
  description = "Microbosh internal IP"
  default     = "10.0.0.6"
}

variable "web_access_cidrs" {
  description = "CSV of CIDR addresses for which we allow web access"
  default     = "80.194.77.90/32,80.194.77.100/32,85.133.67.244/32"
}
