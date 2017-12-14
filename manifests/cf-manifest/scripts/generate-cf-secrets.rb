#!/usr/bin/env ruby

require 'optparse'
require 'yaml'
require File.expand_path("../../../shared/lib/secret_generator", __FILE__)

generator = SecretGenerator.new(
  "bbs_encryption_key" => :simple,
  "bulk_api_password" => :simple,
  "cc_db_encryption_key" => :simple,
  "cdn_broker_admin_password" => :simple,
  "cdn_db_master_password" => :simple,
  "cf_db_api_password" => :simple,
  "cf_db_bbs_password" => :simple,
  "cf_db_locket_password" => :simple,
  "cf_db_master_password" => :simple,
  "cf_db_uaa_password" => :simple,
  "compose_broker_admin_password" => :simple,
  "consul_encrypt_keys" => :simple_in_array,
  "elasticache_broker_auth_token_seed" => :simple,
  "elasticache_broker_admin_password" => :simple,
  "grafana_admin_password" => :simple,
  "kibana_admin_password" => :simple,
  "loggregator_endpoint_shared_secret" => :simple,
  "nats_password" => :simple,
  "rds_broker_admin_password" => :simple,
  "rds_broker_master_password_seed" => :simple,
  "rds_broker_state_encryption_key" => :simple,
  "route_services_secret" => :simple,
  "router_password" => :simple,
  "ssh_proxy_host_key" => :ssh_key,
  "staging_upload_password" => :simple,
  "test_user_password" => :simple,
  "uaa_admin_client_secret" => :simple,
  "uaa_admin_password" => :simple,
  "uaa_batch_password" => :simple,
  "uaa_cc_client_secret" => :simple,
  "uaa_cc_routing_secret" => :simple,
  "uaa_clients_cc_service_dashboards_password" => :simple,
  "uaa_clients_cc_service_key_client_secret" => :simple,
  "uaa_clients_cdn_broker_secret" => :simple,
  "uaa_clients_cloud_controller_username_lookup_secret" => :simple,
  "uaa_clients_datadog_firehose_password" => :simple,
  "uaa_clients_doppler_secret" => :simple,
  "uaa_clients_firehose_password" => :simple,
  "uaa_clients_gorouter_secret" => :simple,
  "uaa_clients_login_secret" => :simple,
  "uaa_clients_notifications_secret" => :simple,
  "uaa_clients_paas_metrics_secret" => :simple,
  "uaa_clients_paas_usage_events_collector_secret" => :simple,
  "uaa_clients_paas_admin_secret" => :simple,
  "uaa_clients_ssh_proxy_secret" => :simple,
  "vcap_password" => :sha512_crypted,
)

option_parser = OptionParser.new do |opts|
  opts.on('--existing-secrets FILE') do |file|
    existing_secrets = YAML.load_file(file)
    # An empty file parses as false
    generator.existing_secrets = existing_secrets["secrets"] if existing_secrets
  end
end
option_parser.parse!

output = { "secrets" => generator.generate }
puts output.to_yaml
