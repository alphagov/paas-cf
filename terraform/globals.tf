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

  default = {
    zone0 = "eu-west-1a"
    zone1 = "eu-west-1b"
    zone2 = "eu-west-1c"
  }
}

variable "zone_index" {
  description = "AWS availability zone indices"

  default = {
    eu-west-1a = "0"
    eu-west-1b = "1"
    eu-west-1c = "2"
  }
}

variable "zone_labels" {
  description = "AWS availability zone labels as used in BOSH manifests (z1-z3)"

  default = {
    eu-west-1a = "z1"
    eu-west-1b = "z2"
    eu-west-1c = "z3"
  }
}

variable "zone_count" {
  description = "Number of zones to use"
  default     = 3
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

variable "microbosh_ips" {
  description = "MicroBOSH IPs per zone"

  default = {
    eu-west-1a = "10.0.0.6"
    eu-west-1b = "10.0.1.6"
    eu-west-1c = "10.0.2.6"
  }
}

variable "infra_subnet_ids" {
  description = "A comma separated list of infrastructure subnets"
  default     = ""
}

variable "microbosh_static_private_ip" {
  description = "Microbosh internal IP"
  default     = "10.0.0.6"
}

/* Operators will mainly be from the office. See https://sites.google.com/a/digital.cabinet-office.gov.uk/gds-internal-it/news/aviationhouse-sourceipaddresses for details. */
variable "admin_cidrs" {
  description = "List of CIDR addresses with access to operator/admin endpoints"

  default = [
    "80.194.77.90/32",
    "80.194.77.100/32",
    "85.133.67.244/32",
  ]
}

/* Note: This is overridden in prod.tfvars to allow specific tenant access */
variable "tenant_cidrs" {
  description = "List of CIDR addresses of tenants with access to CloudFoundry API"
  default     = []
}

/* Note: This is overridden in prod.tfvars to allow world access */
variable "web_access_cidrs" {
  description = "List of CIDR addresses with access to "
  default     = []
}

# See https://docs.aws.amazon.com/elasticloadbalancing/latest/classic/elb-security-policy-table.html
variable "default_elb_security_policy" {
  description = "Which Security policy to use for ELBs. This controls things like available SSL protocols/ciphers."
  default     = "ELBSecurityPolicy-2016-08"
}

# List of Elastic Load Balancing Account ID to configure ELB access log policies
# Provided by AWS in http://docs.aws.amazon.com/ElasticLoadBalancing/latest/DeveloperGuide/enable-access-logs.html
variable "elb_account_ids" {
  default = {
    us-east-1      = "127311923021"
    us-west-1      = "027434742980"
    us-west-2      = "797873946194"
    eu-west-1      = "156460612806"
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

variable "assets_prefix" {
  description = "Prefix for global assests like S3 buckets"
  default     = "gds-paas"
}
