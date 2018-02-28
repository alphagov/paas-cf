#!/usr/bin/env ruby

require 'yaml'

list_secrets_to_keep = %w{
  secrets_bbs_encryption_key
  secrets_cc_db_encryption_key
  secrets_cdn_broker_admin_password
  secrets_cdn_db_master_password
  secrets_cf_db_api_password
  secrets_cf_db_bbs_password
  secrets_cf_db_locket_password
  secrets_cf_db_master_password
  secrets_cf_db_uaa_password
  secrets_compose_broker_admin_password
  secrets_consul_encrypt_keys
  secrets_elasticache_broker_auth_token_seed
  secrets_elasticache_broker_admin_password
  secrets_kibana_admin_password
  secrets_nats_password
  secrets_rds_broker_admin_password
  secrets_rds_broker_master_password_seed
  secrets_rds_broker_state_encryption_key
  secrets_route_services_secret
  secrets_ssh_proxy_host_key
  secrets_uaa_admin_password
  secrets_uaa_clients_cc_service_dashboards_password
  secrets_uaa_clients_cdn_broker_secret
  secrets_uaa_clients_datadog_firehose_password
}

existing_secrets = YAML.safe_load(STDIN)

existing_secrets = existing_secrets.select { |k, _v| list_secrets_to_keep.include?(k) } if existing_secrets
puts existing_secrets.to_yaml
