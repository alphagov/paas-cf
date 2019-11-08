#!/usr/bin/env ruby
require 'yaml'
require 'rest-client'

require_relative './lib/actions'
require_relative './lib/user'

UAA_API_URL = ENV.fetch('UAA_API_URL')
CF_TOKEN    = ENV.fetch('CF_TOKEN')
USERS_CONFIG_PATH = ENV.fetch('USERS_CONFIG_PATH')

uaa_client = RestClient::Resource.new(
  UAA_API_URL,
  headers: {
    'Authorization' => CF_TOKEN,
    'Content-Type' => 'application/json'
  }
)
users_config = YAML.safe_load(File.read(USERS_CONFIG_PATH)).map { |uo| User.new(uo) }

ensure_users_exist_in_uaa(users_config, uaa_client)

admin_users = users_config.select(&:cf_admin)
groups = [
  Group.new('cloud_controller.admin', admin_users),
  Group.new('cloud_controller.admin_read_only', admin_users),
  Group.new('uaa.admin', admin_users),
  Group.new('scim.read', admin_users),
  Group.new('scim.write', admin_users),
  Group.new('scim.invite', admin_users),
  Group.new('doppler.firehose', admin_users),
  Group.new('network.admin', admin_users),
  Group.new('cloud_controller.global_auditor', users_config)
]

ensure_uaa_groups_have_correct_members(groups, uaa_client)
