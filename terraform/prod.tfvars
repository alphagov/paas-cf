aws_account = "prod"
system_dns_zone_id = "Z39UURGVWSYTHL"
apps_dns_zone_id = "Z29K8LQNCFDZ1T"
cf_db_multi_az = "true"
bosh_db_multi_az = "true"
cf_db_backup_retention_period = "35"
cf_db_skip_final_snapshot = "false"
cf_db_maintenance_window = "Thu:07:00-Thu:08:00"
cf_db_instance_type = "db.m4.xlarge"
cdn_db_multi_az = "true"
cdn_db_backup_retention_period = "35"
cdn_db_skip_final_snapshot = "false"
cdn_db_maintenance_window = "Thu:07:00-Thu:08:00"
bosh_db_backup_retention_period = "35"
bosh_db_skip_final_snapshot = "false"
support_email="gov-uk-paas-support@digital.cabinet-office.gov.uk"

apps_wildcard_weight="100"
apps_wildcard_canary_weight="0"

# 14313358 - GOV.UK PaaS Contact - prod
# 14270734 - PaaS PagerDuty 24x7
pingdom_contact_ids = [ 14313358, 14270734 ]
