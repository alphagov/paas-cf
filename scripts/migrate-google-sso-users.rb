require 'csv'
require 'uri'
require File.expand_path("../lib/uaa_sync_admin_users", __FILE__)

# rubocop:disable Lint/RequireParentheses, Style/MultilineTernaryOperator
module CF
  module UAA
    module Http
      def json_parse_reply(style, status, body, headers)
        raise ArgumentError unless style.nil? || style.is_a?(Symbol)
        unless [200, 201, 204, 400, 401, 403, 409, 422].include? status
          raise (status == 404 ? NotFound : BadResponse), "invalid status response: #{status}"
        end
        if body && !body.empty? && (status == 204 || headers.nil? ||
              headers['content-type'] !~ /application\/json/i)
          raise BadResponse, 'received invalid response content or type'
        end
        parsed_reply = Util.json_parse(body, style)
        if status >= 400
          puts parsed_reply.inspect
          raise parsed_reply && parsed_reply['error'] == 'invalid_token' ?
              InvalidToken.new(parsed_reply) : TargetError.new(parsed_reply), 'error response'
        end
        parsed_reply
      rescue DecodeError
        raise BadResponse, 'invalid JSON response'
      end
    end
  end
end
# rubocop:enable Lint/RequireParentheses, Style/MultilineTernaryOperator

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
      next
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
google_users = all_users.select { |u| u["origin"] == "google" }
google_usernames = google_users.map { |u| u["username"] }
non_numeric_google_usernames = google_usernames.reject { |username| username.match("[^0-9]").nil? }

if non_numeric_google_usernames.length.empty?
  puts "SUCCESS: All Google users have numeric usernames"
else
  puts "FAILURE: This does not seem to have transitioned all Google users to using numeric usernames."
  puts "The following usernames are not entirely numeric:"
  non_numeric_google_usernames.each do |username|
    puts "  #{username}"
  end
end
