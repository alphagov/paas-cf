#!/usr/bin/env ruby

require 'optparse'
require 'yaml'
require File.expand_path("../../../shared/lib/secret_generator", __FILE__)

generator = SecretGenerator.new({
  "vcap_password" =>  :sha512_crypted,
  "cf_db_master_password" => :simple,
  "cf_db_api_password" => :simple,
  "cf_db_uaa_password" => :simple,
  "staging_upload_password" => :simple,
  "bulk_api_password" => :simple,
  "nats_password" => :simple,
  "router_password" => :simple,
  "uaa_batch_password" => :simple,
  "uaa_admin_password" => :simple,
  "cc_db_encryption_key" => :simple,
  "uaa_admin_client_secret" => :simple,
  "uaa_cc_client_secret" => :simple,
  "uaa_cc_routing_secret" => :simple,
  "uaa_clients_app_direct_secret" => :simple,
  "uaa_clients_developer_console_secret" => :simple,
  "uaa_clients_login_secret" => :simple,
  "uaa_clients_notifications_secret" => :simple,
  "uaa_clients_doppler_secret" => :simple,
  "uaa_clients_cloud_controller_username_lookup_secret" => :simple,
  "uaa_clients_gorouter_secret" => :simple,
  "uaa_clients_firehose_password" => :simple,
  "loggregator_endpoint_shared_secret" => :simple,
  "consul_encrypt_keys" => :simple_in_array,
  "grafana_admin_password" => :simple,
  "rds_broker_admin_password" => :simple,
})

OptionParser.new do |opts|
  opts.on('--existing-secrets FILE') do |file|
    existing_secrets = YAML.load_file(file)
    # An empty file parses as false
    generator.existing_secrets = existing_secrets["secrets"] if existing_secrets
  end
end.parse!

output = { "secrets" => generator.generate }
puts output.to_yaml
