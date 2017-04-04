aws_account = "prod"
system_dns_zone_id = "Z39UURGVWSYTHL"
apps_dns_zone_id = "Z29K8LQNCFDZ1T"
cf_db_multi_az = "true"
bosh_db_multi_az = "true"
cf_db_backup_retention_period = "35"
cf_db_skip_final_snapshot = "false"
cf_db_maintenance_window = "Thu:07:00-Thu:08:00"
web_access_cidrs = [
  "0.0.0.0/0",
]
tenant_cidrs = [
  # BitZesty (trade-tarrif)
  "52.19.165.178/32",
  # DIT
  "52.49.20.243/32",
  "81.149.93.91/32",
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
  "34.251.16.209/32",
  # GOV.UK Notify egress IPs (for metrics gathering)
  "52.209.11.109/32",
  "52.212.153.196/32",
  "52.19.155.10/32",
  "52.213.138.76/32",
  "52.213.151.67/32",
  "52.208.47.129/32",
  # Cabinet office trial
  "85.133.79.201/32",
  # Parliamentary web services trial
  "82.35.29.203/32",
  # Digital Marketplace Jenkins
  "52.18.174.104/32",
  # DWP Bereavement Payment Support
  "194.73.212.3/32",
  # MOJ Digital and Technology
  "81.134.202.29/32",
  # Tenant egress for story #140308141
  "185.40.8.212/32",
  "86.188.177.234/32",
  # Our own build Concourse in CI
  "52.213.245.135/32",
  # mod-dbs-trial org
  "82.6.141.121/32",
  "31.122.47.191/32",
  # Innovision/DIT Horizon
  "87.224.83.58/32",
  # Notify NAT IPs to export data to paas
  "52.18.54.222/32",
  "52.208.148.20/32",
  "52.208.3.206/32",
  # BEIS platform team
  "193.240.203.38/32",
  "82.45.99.124/32",
  "52.56.227.113/32",
  # DWP Carer's Allowance
  "194.159.238.241/32",
  "212.250.23.69/32",
  "212.250.43.3/32",
  # DWP Overseas Healthcare Service Trial
  "217.33.141.90/32",
]
bosh_db_backup_retention_period = "35"
bosh_db_skip_final_snapshot = "false"
support_email="gov-uk-paas-support@digital.cabinet-office.gov.uk"
enable_cve_monitor=1

# Enable the pagerduty notifications
enable_pagerduty_notifications = 1
pingdom_contact_ids = [ 11089310, 11189971 ]

datadog_notification_24x7 = "@pagerduty-datadog-24x7"
datadog_notification_in_hours = "@pagerduty-datadog-in-hours"
