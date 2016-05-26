#!/usr/bin/env ruby
require 'json'
require 'yaml'
require 'net/https'

require File.expand_path("../lib/mail_credentials_helper", __FILE__)
require File.expand_path("../lib/uaa_sync_admin_users", __FILE__)

def get_uaa_target(api_url)
  uri = URI.parse(api_url) + "/v2/info"
  http = Net::HTTP.new(uri.host, uri.port)
  if uri.instance_of? URI::HTTPS
    http.use_ssl=true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE if ENV['SKIP_SSL_VERIFICATION'].to_s.downcase == "true"
  end
  response = http.request(Net::HTTP::Get.new(uri.request_uri))
  if response.code != "200"
    raise "Error connecting to API endpoint #{uri}: #{response}"
  end
  api_info = JSON.load(response.body)
  api_info["token_endpoint"]
end

def load_admin_user_list(filename)
  users = YAML.load_file(filename)
  users.each_with_index.map { |u, i|
    {
      username: u["username"] || u["email"],
      email: u["email"] || raise("User #{i} defined in file #{filename} is missing email"),
      gpg_key: u["gpg_key"] || raise("User #{i} defined in file #{filename} is missing gpg_key"),
    }
  }
end

api_url = ARGV[0] || raise("You must pass API endpoint as first argument")
users_filename = ARGV[1] || raise("You must pass a file of users as second argument")

admin_user = ENV['UAA_CLIENT'] || "admin"
admin_password = ENV['UAA_CLIENT_SECRET'] || raise("Must set $UAA_CLIENT_SECRET env var")

puts "Syncing Admin users in #{api_url}..."

target = get_uaa_target(api_url)
users = load_admin_user_list(users_filename)

options = {}
options[:skip_ssl_validation] = true if ENV['SKIP_SSL_VERIFICATION'].to_s.downcase == "true"

uaa_sync_admin_users = UaaSyncAdminUsers.new(target, admin_user, admin_password, options)
uaa_sync_admin_users.request_token()
created_users, deleted_users = uaa_sync_admin_users.update_admin_users(users)

created_users.each { |user|
  puts "Sending credentials to new user #{user[:username]}"
  EmailCredentialsHelper.send_admin_credentials(api_url, user)
}

puts "Created users: #{created_users.length}"
created_users.each { |u|
  puts " - #{u[:username]}"
}
puts "Deleted users: #{deleted_users.length}"
deleted_users.each { |u|
  puts " - #{u[:username]}"
}

