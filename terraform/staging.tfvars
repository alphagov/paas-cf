aws_account = "staging"
system_dns_zone_id = "ZPFAUK62IO6DS"
apps_dns_zone_id = "Z32JRRSU1CAFE8"
cf_db_multi_az = "true"
bosh_db_multi_az = "true"
cf_db_backup_retention_period = "35"
cf_db_skip_final_snapshot = "false"
cf_db_maintenance_window = "Wed:07:00-Wed:08:00"
cf_db_instance_type = "db.m4.large"
cdn_db_multi_az = "true"
cdn_db_backup_retention_period = "35"
cdn_db_skip_final_snapshot = "false"
cdn_db_maintenance_window = "Wed:07:00-Wed:08:00"
bosh_db_backup_retention_period = "35"
bosh_db_skip_final_snapshot = "false"
support_email="govpaas-alerting-staging@digital.cabinet-office.gov.uk"

apps_wildcard_weight="100"
apps_wildcard_canary_weight="0"

# 14313354 - GOV.UK PaaS Contact - staging
# 14270725 - PaaS PagerDuty in hours
pingdom_contact_ids = [ 14313354, 14270725 ]
