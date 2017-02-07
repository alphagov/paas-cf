aws_account = "staging"
system_dns_zone_id = "ZPFAUK62IO6DS"
apps_dns_zone_id = "Z32JRRSU1CAFE8"
cf_db_multi_az = "true"
bosh_db_multi_az = "true"
cf_db_backup_retention_period = "35"
cf_db_skip_final_snapshot = "false"
cf_db_maintenance_window = "Wed:04:00-Wed:05:00"
web_access_cidrs = [
  "0.0.0.0/0",
]
bosh_db_backup_retention_period = "35"
bosh_db_skip_final_snapshot = "false"
support_email="govpaas-alerting-staging@digital.cabinet-office.gov.uk"

# Enabled/disabled resources
# Disable datadog_monitor.total_routes_drop resource
datadog_monitor_total_routes_drop_enabled = 0
pingdom_contact_ids = [ 11089310, 11190300 ]

datadog_notification_24x7 = "@pagerduty-datadog-in-hours"
datadog_notification_in_hours = "@pagerduty-datadog-in-hours"
