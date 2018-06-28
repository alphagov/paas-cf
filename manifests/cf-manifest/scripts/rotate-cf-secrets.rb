#!/usr/bin/env ruby

require 'yaml'

# cf-secrets.yml
list_secrets_to_keep = %w{
  secrets_cdn_db_master_password
  secrets_cf_db_master_password
  external_bbs_database_password
  external_cc_database_password
  external_locket_database_password
  external_uaa_database_password
}

existing_secrets = YAML.safe_load(STDIN)

existing_secrets = existing_secrets.select { |k, _v| list_secrets_to_keep.include?(k) } if existing_secrets
puts existing_secrets.to_yaml
