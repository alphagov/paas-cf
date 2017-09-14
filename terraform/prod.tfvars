aws_account = "prod"
system_dns_zone_id = "Z39UURGVWSYTHL"
apps_dns_zone_id = "Z29K8LQNCFDZ1T"
cf_db_multi_az = "true"
bosh_db_multi_az = "true"
cf_db_backup_retention_period = "35"
cf_db_skip_final_snapshot = "false"
cf_db_maintenance_window = "Thu:07:00-Thu:08:00"
cdn_db_multi_az = "true"
cdn_db_backup_retention_period = "35"
cdn_db_skip_final_snapshot = "false"
cdn_db_maintenance_window = "Thu:07:00-Thu:08:00"
bosh_db_backup_retention_period = "35"
bosh_db_skip_final_snapshot = "false"
support_email="gov-uk-paas-support@digital.cabinet-office.gov.uk"
enable_compose_scraper=1

# Enable the pagerduty notifications
enable_pagerduty_notifications = 1
pingdom_contact_ids = [ 11089310, 11189971 ]

datadog_notification_24x7 = "@pagerduty-datadog-24x7"
datadog_notification_in_hours = "@pagerduty-datadog-in-hours"
