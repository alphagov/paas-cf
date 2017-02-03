aws_account = "prod"
system_dns_zone_id = "Z39UURGVWSYTHL"
apps_dns_zone_id = "Z29K8LQNCFDZ1T"
cf_db_multi_az = "true"
bosh_db_multi_az = "true"
cf_db_backup_retention_period = "35"
cf_db_skip_final_snapshot = "false"
cf_db_maintenance_window = "Thu:04:00-Thu:05:00"
web_access_cidrs = [
  "0.0.0.0/0",
]
tenant_cidrs = [
  # BitZesty (trade-tarrif)
  "52.19.165.178/32",
  # DIT
  "52.49.20.243/32",
  # HMPO trial
  "52.18.106.146/32",
  # Usability Jenkins EIP
  "52.212.106.102/32",
  # Verify Jenkins server
  "37.26.93.212/32",
  # Shockley
  "80.194.77.64/26",
  # DWP carers trial
  "84.93.121.196/32",
  # DBS team
  "195.171.79.218/32",
  # MOD PaaS Trial
  "25.8.49.225/32",
  "25.8.49.187/32",
  # GOV.UK Notify Jenkins server
  "52.214.41.17/32",
  # Accessing Government Services team Jenkins server
  "52.214.76.50/32",
  # GOV.UK Pay CI node
  "52.210.67.64/32",
  # GOV.UK Notify egress IPs (for metrics gathering)
  "52.209.11.109/32",
  "52.212.153.196/32",
  "52.19.155.10/32",
  "52.213.138.76/32",
  "52.213.151.67/32",
  "52.208.47.129/32",
]
bosh_db_backup_retention_period = "35"
bosh_db_skip_final_snapshot = "false"
support_email="gov-uk-paas-support@digital.cabinet-office.gov.uk"
enable_cve_monitor=1

# Enable the pagerduty notifications
enable_pagerduty_notifications = 1
