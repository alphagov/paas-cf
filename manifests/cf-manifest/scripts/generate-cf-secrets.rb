#!/usr/bin/env ruby

require 'optparse'
require 'yaml'
require File.expand_path("../../../shared/lib/secret_generator", __FILE__)

generator = SecretGenerator.new(
  "secrets_bbs_encryption_key" => :simple,
  "secrets_bulk_api_password" => :simple,
  "secrets_cc_db_encryption_key" => :simple,
  "secrets_cdn_broker_admin_password" => :simple,
  "secrets_cdn_db_master_password" => :simple,
  "secrets_cf_db_api_password" => :simple,
  "secrets_cf_db_bbs_password" => :simple,
  "secrets_cf_db_locket_password" => :simple,
  "secrets_cf_db_master_password" => :simple,
  "secrets_cf_db_uaa_password" => :simple,
  "secrets_cf_db_network_connectivity_password" => :simple,
  "secrets_cf_db_network_policy_password" => :simple,
  "secrets_compose_broker_admin_password" => :simple,
  "secrets_paas_accounts_admin_password" => :simple,
  "secrets_consul_encrypt_keys" => :simple_in_array,
  "secrets_elasticache_broker_admin_password" => :simple,
  "secrets_kibana_admin_password" => :simple,
  "secrets_loggregator_endpoint_shared_secret" => :simple,
  "secrets_nats_password" => :simple,
  "secrets_rds_broker_admin_password" => :simple,
  "secrets_rds_broker_master_password_seed" => :simple,
  "secrets_rds_broker_state_encryption_key" => :simple,
  "secrets_route_services_secret" => :simple,
  "secrets_router_password" => :simple,
  "secrets_ssh_proxy_host_key" => :ssh_key,
  "secrets_staging_upload_password" => :simple,
  "secrets_test_user_password" => :simple,
  "secrets_uaa_admin_client_secret" => :simple,
  "secrets_uaa_admin_password" => :simple,
  "secrets_uaa_batch_password" => :simple,
  "secrets_uaa_cc_client_secret" => :simple,
  "secrets_uaa_cc_routing_secret" => :simple,
  "secrets_uaa_clients_cc_service_dashboards_password" => :simple,
  "secrets_uaa_clients_cc_service_key_client_secret" => :simple,
  "secrets_uaa_clients_cdn_broker_secret" => :simple,
  "secrets_uaa_clients_cloud_controller_username_lookup_secret" => :simple,
  "secrets_uaa_clients_datadog_firehose_password" => :simple,
  "secrets_uaa_clients_doppler_secret" => :simple,
  "secrets_uaa_clients_gorouter_secret" => :simple,
  "secrets_uaa_clients_login_secret" => :simple,
  "secrets_uaa_clients_notifications_secret" => :simple,
  "secrets_uaa_clients_paas_metrics_secret" => :simple,
  "secrets_uaa_clients_paas_billing_secret" => :simple,
  "secrets_uaa_clients_ssh_proxy_secret" => :simple,
  "secrets_vcap_password" => :sha512_crypted,
)

option_parser = OptionParser.new do |opts|
  opts.on('--existing-secrets FILE') do |file|
    existing_secrets = YAML.load_file(file)
    if existing_secrets && existing_secrets["secrets"]
      existing_secrets["secrets"].each { |key, value|
        existing_secrets["secrets_#{key}"] = value
      }
      existing_secrets.delete("secrets")
    end
    # An empty file parses as false
    generator.existing_secrets = existing_secrets if existing_secrets
  end
end
option_parser.parse!

output = generator.generate
puts output.to_yaml
