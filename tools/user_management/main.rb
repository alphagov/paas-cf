#!/usr/bin/env ruby
require 'yaml'
require 'rest-client'

require_relative './lib/actions'
require_relative './lib/user'

UAA_API_URL       = ENV.fetch('UAA_API_URL')
CF_TOKEN          = ENV.fetch('CF_TOKEN')
ENV_TARGET        = ENV.fetch('ENV_TARGET')
USERS_CONFIG_PATH = ENV.fetch('USERS_CONFIG_PATH')

uaa_client = RestClient::Resource.new(
  UAA_API_URL,
  headers: {
    'Authorization' => CF_TOKEN,
    'Content-Type' => 'application/json'
  }
)

users_config = YAML.safe_load(File.read(USERS_CONFIG_PATH), aliases: true)
users = users_config.fetch('users').map { |uo| User.new(uo) }
cf_admin_users = users.select { |user| user.has_role_for_env?(ENV_TARGET, 'cf-admin') }
cf_auditor_users = users.select { |user| user.has_role_for_env?(ENV_TARGET, 'cf-auditor') }

ensure_users_exist_in_uaa(cf_admin_users + cf_auditor_users, uaa_client)

groups = [
  Group.new('cloud_controller.admin', cf_admin_users),
  Group.new('cloud_controller.admin_read_only', cf_admin_users),
  Group.new('uaa.admin', cf_admin_users),
  Group.new('scim.read', cf_admin_users),
  Group.new('scim.write', cf_admin_users),
  Group.new('scim.invite', cf_admin_users),
  Group.new('doppler.firehose', cf_admin_users),
  Group.new('network.admin', cf_admin_users),
  Group.new('cloud_controller.global_auditor', cf_auditor_users)
]

ensure_uaa_groups_have_correct_members(groups, uaa_client)
