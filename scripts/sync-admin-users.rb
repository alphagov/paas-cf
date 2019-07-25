#!/usr/bin/env ruby
require 'yaml'

require File.expand_path("../lib/mail_credentials_helper", __FILE__)
require File.expand_path("../lib/uaa_sync_admin_users", __FILE__)

def load_admin_user_list(filename, deploy_env)
  users = YAML.load_file(filename)
  users
    .select { |u| u.fetch('deploy_envs', []).include? deploy_env }
    .select { |u| u.fetch('cf_admin', false) }
    .each_with_index.map { |u, i|
    {
      username: u.fetch("google_id") || raise("User #{i} defined in file #{filename} is missing google_id"),
      email: u["email"] || raise("User #{i} defined in file #{filename} is missing email"),
      origin: u.fetch("origin", "uaa"),
    }
  }
end

cf_api_url = ARGV[0] || raise("You must pass API endpoint as first argument")
users_filename = ARGV[1] || raise("You must pass a file of users as second argument")
source_address = ARGV[2] || raise("You must pass an SES-validated address as third argument")
deploy_env     = ARGV[3] || raise("You must pass the deploy env as fourth argument")

cf_admin_username = 'admin'
cf_admin_password = ENV['CF_ADMIN_PASSWORD'] || raise("Must set $CF_ADMIN_PASSWORD env var")

puts "Syncing Admin users in #{cf_api_url}..."

users = load_admin_user_list(users_filename, deploy_env)

options = {}
options[:skip_ssl_validation] = true if ENV['SKIP_SSL_VERIFICATION'].to_s.casecmp("true").zero?

uaa_sync_admin_users = UaaSyncAdminUsers.new(cf_api_url, cf_admin_username, cf_admin_password, options)
uaa_sync_admin_users.request_token
created_users, deleted_users = uaa_sync_admin_users.update_admin_users(users)

created_users.each { |user|
  puts "Sending notification to new user #{user.fetch(:username)}"
  EmailCredentialsHelper.send_notification(cf_api_url, user, source_address)
}

puts "Created users: #{created_users.length}"
created_users.each { |u|
  puts " - #{u.fetch(:username)}"
}
puts "Deleted users: #{deleted_users.length}"
deleted_users.each { |u|
  puts " - #{u.fetch(:username)}"
}
