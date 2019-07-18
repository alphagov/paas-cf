require 'csv'
require 'uri'
require File.expand_path("../lib/uaa_sync_admin_users", __FILE__)

file_path = ARGV[0] || raise("You must pass the path to the user ids CSV as first argument")
cf_api_url = ARGV[1] || raise("You must pass API endpoint as second argument")
cf_admin_username = 'admin'
cf_admin_password = ENV['CF_ADMIN_PASSWORD'] || raise("Must set $CF_ADMIN_PASSWORD env var")

options = {}
options[:skip_ssl_validation] = true if ENV['SKIP_SSL_VERIFICATION'].to_s.casecmp("true").zero?

uaa_sync_admin_users = UaaSyncAdminUsers.new(cf_api_url, cf_admin_username, cf_admin_password, options)
uaa_sync_admin_users.request_token


csv_lines = CSV.read(file_path)

email_to_id_map = {}

csv_lines.each { |line|
  email_to_id_map[line[0]] = line[1]
}
id_to_email_map = email_to_id_map.invert

puts "===> Considering the following email addresses"
puts email_to_id_map.keys


puts ""
puts "===> Fetching & updating users"
pad = email_to_id_map.keys.max_by(&:length).length
email_to_id_map.each { |email, id|
  user = uaa_sync_admin_users.get_user_by_username(email)

  if user == nil
    puts email.rjust(pad) + ": NOT FOUND"
  else
    if user["origin"] != "google"
      puts email.rjust(pad) + ": NOT A GOOGLE USER"
      continue
    end

    puts email.rjust(pad) + ": WILL UPDATE TO ID " + id
    user["username"] = id
    uaa_sync_admin_users.update_user(user)
    puts email.rjust(pad) + ": Updated UAA user " + user["id"]
  end
}

puts ""
puts "==> Verifying all Google SSO users have been migrated"
all_users = uaa_sync_admin_users.get_all_users
usernames = all_users.map { |u| u["username"] }
pad = usernames.max_by(&:length).length
all_users.each { |user|
  if user["origin"] != "google"
    next
  elsif user["origin"] == "google"
    if user["username"].match("\d{20,}") != nil
      puts user["username"].rjust(pad) + ": FAILURE. SHOULD HAVE BEEN SOMETHING LIKE A GOOGLE ID"
      next
    end
  end

  if user["username"].match(URI::MailTo::EMAIL_REGEXP) != nil
    puts user["username"].rjust(pad) + ": FAILURE"
  else
    puts user["username"].rjust(pad) + ": PASS (username: " + id_to_email_map[user["username"]] + ")"
  end
}
