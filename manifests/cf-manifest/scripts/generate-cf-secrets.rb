#!/usr/bin/env ruby

require 'optparse'
require 'yaml'
require File.expand_path("../../../shared/lib/secret_generator", __FILE__)

generator = SecretGenerator.new(
  # Passwords for DBs generated in terraform
  "secrets_cf_db_master_password" => :simple,
  "secrets_cdn_db_master_password" => :simple,
  "external_cc_database_password" => :simple,
  "external_bbs_database_password" => :simple,
  "external_locket_database_password" => :simple,
  "external_uaa_database_password" => :simple,
  "external_silk_controller_database_password" => :simple,
  "external_policy_server_database_password" => :simple,
  # SHA512 password for vms
  # This secret is used in the cloud-config to set the password for the
  # vcap user. But we do not really login ever as vcap git user directly
  # NOTE: pending confirm.
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
