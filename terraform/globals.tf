/* Operators will mainly be from the office. See https://sites.google.com/a/digital.cabinet-office.gov.uk/gds-internal-it/news/aviationhouse-sourceipaddresses for details. */
variable "admin_cidrs" {
  description = "List of CIDR addresses with access to operator/admin endpoints"

  default = [
    "217.196.229.80/32", # GDS BYOD VPN (Sep 2023)
    "217.196.229.81/32",
    "217.196.229.77/32", # GovWifi (Sep 2023)
    "217.196.229.79/32", # Brattain (Sep 2023)
    # Remove after 1 Oct 2023
    "213.86.153.211/32", # New BYOD VPN IP
    "213.86.153.212/32",
    "213.86.153.213/32",
    "213.86.153.214/32",
    "213.86.153.231/32", # New BYOD VPN IP
    "213.86.153.235/32",
    "213.86.153.236/32",
    "213.86.153.237/32",
    "51.149.8.0/25",   # New DR VPN
    "51.149.8.128/29", # New DR BYOD VPN
    # Don't remove
    "90.155.48.192/26",  # ITHC 2023
    "81.2.127.144/28",   # ITHC 2023
    "81.187.169.170/32", # ITHC 2023
    "88.97.60.11/32",    # ITHC 2023
    "3.10.4.97/32",      # ITHC 2023
    "51.104.217.191/32", # ITHC 2023
  ]
}

/* Note: This is overridden in dev.tfvars to disallow world access */
variable "api_access_cidrs" {
  description = "List of CIDR addresses with access to CloudFoundry API"
  default     = ["0.0.0.0/0"]
}

variable "assets_prefix" {
  description = "Prefix for global assests like S3 buckets"
  default     = "gds-paas"
}

variable "aws_account" {
  description = "the AWS account being deployed to"
}

# See https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#tls-security-policies
variable "default_load_balancer_security_policy" {
  description = "Which Security policy to use for ALBs and NLBs. This controls things like available SSL protocols/ciphers."
  default     = "ELBSecurityPolicy-TLS-1-2-Ext-2018-06"
}

# See https://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-security-policy-table.html
variable "default_classic_load_balancer_security_policy" {
  description = "Which Security policy to use for classic load balancers. This controls things like available SSL protocols/ciphers."
  default     = "ELBSecurityPolicy-TLS-1-2-2017-01"
}

# List of Elastic Load Balancing Account ID to configure ELB access log policies
# Provided by AWS in http://docs.aws.amazon.com/ElasticLoadBalancing/latest/DeveloperGuide/enable-access-logs.html
variable "elb_account_ids" {
  default = {
    us-east-1      = "127311923021"
    us-west-1      = "027434742980"
    us-west-2      = "797873946194"
    eu-west-1      = "156460612806"
    eu-west-2      = "652711504416"
    eu-central-1   = "054676820928"
    ap-northeast-1 = "582318560864"
    ap-northeast-2 = "600734575887"
    ap-southeast-1 = "114774131450"
    ap-southeast-2 = "783225319266"
    ap-south-1     = "718504428378"
    sa-east-1      = "507241528517"
    us-gov-west-1  = "048591011584"
    cn-north-1     = "638102146993"
  }
}

variable "env" {
  description = "Environment name"
}

variable "infra_cidrs" {
  description = "CIDR for infrastructure subnet indexed by AZ"

  default = {
    zone0 = "10.0.0.0/24"
    zone1 = "10.0.1.0/24"
    zone2 = "10.0.2.0/24"
  }
}

variable "infra_gws" {
  description = "GW per CIDR"

  default = {
    "10.0.0.0/24" = "10.0.0.1"
    "10.0.1.0/24" = "10.0.1.1"
    "10.0.2.0/24" = "10.0.2.1"
  }
}

variable "infra_subnet_ids" {
  description = "A comma separated list of infrastructure subnets"
  default     = ""
}

variable "microbosh_ips" {
  description = "MicroBOSH IPs per zone"
  type        = map(string)
}

variable "microbosh_static_private_ip" {
  description = "Microbosh internal IP"
  default     = "10.0.0.6"
}

variable "pingdom_contact_ids" {
  description = "The IDs of the contacts in Pingdom who should be alerted"
  default     = []
}

variable "region" {
  description = "AWS region"
}

variable "support_email" {
  description = "The email address on which to contact GOV.UK PaaS"
  default     = ""
}

variable "vpc_cidr" {
  description = "CIDR for VPC"
  default     = "10.0.0.0/16"
}

variable "vpc_id" {
  description = "id of VPC created in main 'vpc' terraform"
  default     = ""
}

variable "zone_count" {
  description = "Number of zones to use"
}

variable "zones" {
  description = "AWS availability zones"
  type        = map(string)
}

variable "user_static_cidrs" {
  description = "user static_cidrs populated with values from paas-trusted-people"
  default     = []
}
