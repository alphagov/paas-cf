aws_account = "ci"
system_dns_zone_id = "Z2PF4LCV9VR1MV"
apps_dns_zone_id = "Z29I9K6RNC6344"
cf_db_multi_az = "false"
cf_db_backup_retention_period = "0"
cf_db_skip_final_snapshot = "true"
cf_db_maintenance_window = "Tue:04:00-Tue:05:00"
support_email="govpaas-alerting-ci@digital.cabinet-office.gov.uk"

# Enabled/disabled resources
# Disable datadog_monitor.total_routes_drop resource
datadog_monitor_total_routes_drop_enabled = 0

pingdom_contact_ids = [ 11089310, 11190300 ]

datadog_notification_24x7 = "@pagerduty-datadog-in-hours"
datadog_notification_in_hours = "@pagerduty-datadog-in-hours"
