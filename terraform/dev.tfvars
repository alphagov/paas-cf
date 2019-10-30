aws_account = "dev"
system_dns_zone_id = "Z1QGLFML8EG6G7"
apps_dns_zone_id = "Z3R6XFWUT4YZHB"
cf_db_multi_az = "false"
cf_db_backup_retention_period = "0"
cf_db_skip_final_snapshot = "true"
cf_db_maintenance_window = "Mon:07:00-Mon:08:00"
cf_db_instance_type = "db.m4.large"
api_access_cidrs = []
cdn_db_multi_az = "false"
cdn_db_backup_retention_period = "0"
cdn_db_skip_final_snapshot = "true"
cdn_db_maintenance_window = "Mon:07:00-Mon:08:00"
support_email="govpaas-alerting-dev@digital.cabinet-office.gov.uk"

apps_wildcard_weight="100"
apps_wildcard_canary_weight="0"

# 14313350 - GOV.UK PaaS Contact - dev
pingdom_contact_ids = [ 14313350 ]
