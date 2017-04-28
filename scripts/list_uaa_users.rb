#!/usr/bin/env ruby

# Configuration
# export TARGET="https://uaa.<SYSTEM DOMAIN>"
# export UAA_CLIENT_USERNAME=admin
# export UAA_CLIENT_PASSWORD=xxx # uaa_admin_client_secret
# export SKIP_SSL_VALIDATION=true

# Uncomment and edit queries below

# Run within paas-cf/scripts
# ./force_user_reset_password.rb | sort -f

require './lib/uaa_sync_admin_users.rb'

target=ENV.fetch("TARGET")
admin_user=ENV.fetch("UAA_CLIENT_USERNAME")
admin_password=ENV.fetch("UAA_CLIENT_PASSWORD")
options = {}
options[:skip_ssl_validation] = ENV.fetch("SKIP_SSL_VALIDATION") == "true"

uaa_sync_admin_users = UaaSyncAdminUsers.new(target, admin_user, admin_password, options)
uaa_sync_admin_users.request_token

# doesn't work :(
# query = { filter: "previouslogontime pr" }
# query = { attributes: "userName previouslogontime" }

# All users
query = { }
# 1 user
# query = { filter: "userName eq 'colin-test'"}
users = uaa_sync_admin_users.ua.all_pages(:user, query)

users.each{ |u|
  # Users who never changed password
  if Time.parse(u['passwordlastmodified']).to_i == Time.parse(u['meta']['created']).to_i and u["origin"] == "uaa"
    puts "#{u['username']}"
  end

  # Users who logged in at least twice
  # puts "#{u['username']}" if u.has_key?('previouslogontime') and u["origin"] == "uaa"

  # Users who logged in at least once
  # puts "#{u['username']}" if u.has_key?('lastlogontime') and u["origin"] == "uaa"

  # Users who never logged in
  # puts "#{u['username']}" if !u.has_key?('lastlogontime') and u["origin"] == "uaa"

  # All users
  # puts "#{u['username']} previous: #{u['previouslogontime']} last: #{u['lastlogontime']}"
  # pp u
}
