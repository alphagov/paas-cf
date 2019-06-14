require 'io/console'
require 'uaa'
require 'json'
require 'English'
require 'net/http'
require 'uri'

USER_PREFIX_BLACKLIST = [
  'CAT-', 'CATS-', 'SMOKE-', 'ACC-'
].freeze

uaac_url = ARGV[0] || raise("you must pass the UAAC URL as the first arg")
accounts_url = ARGV[1] || raise("you must pass the accounts URL as the second arg")
accounts_username = ARGV[2] || raise("you must pass the accounts basic auth username as the third arg")
accounts_password = ARGV[3] || raise("you must pass the accounts basic auth password as the fourth arg")

puts("Targetting accounts API #{accounts_url}")

def get_uaac_token
  `cf oauth-token`.chomp
end

def get_users(api_url, token)
  start_index = 1
  num_results = nil
  users = []

  loop do
    url = "#{api_url}/Users?startIndex=#{start_index}"

    STDERR.puts "curl #{url}"
    response = `curl -s -L -H 'Authorization: #{token}' '#{url}'`
    abort 'Could not get users from UAA' unless $CHILD_STATUS.success?

    response    = JSON.parse(response)
    users       = users.concat(response.dig('resources'))
    num_results = response.dig('totalResults')
    start_index = response.dig('startIndex') + 100

    break if start_index > num_results
  end

  users
end

def user_to_id_email_pair(user)
  [user.dig('id'), user.dig('username')]
end

def get_accounts_user(accounts_url, accounts_username, accounts_password, user_uuid)
  url = URI("#{accounts_url}/users/#{user_uuid}")

  abort 'Failed to get user from accounts' unless $CHILD_STATUS.success?

  http = Net::HTTP.new(url.host, url.port)
  http.use_ssl = true
  request = Net::HTTP::Get.new(url.request_uri)
  request.basic_auth(accounts_username, accounts_password)
  response = http.request(request)

  if response.code == "404"
    return nil
  end

  JSON.parse(response.body)
end

def post_accounts_user(accounts_url, accounts_username, accounts_password, uuid, username)
  url = URI("#{accounts_url}/users/")
  payload = {
    "user_uuid": uuid,
    "user_email": email_or_null(username),
    "username": username
  }.to_json

  http = Net::HTTP::new(url.host, url.port)
  http.use_ssl = true
  request = Net::HTTP::Post.new(url.request_uri, 'Content-Type' => 'application/json')
  request.basic_auth(accounts_username, accounts_password)
  request.body = payload

  response = http.request(request)
  response.code == "201"
end

def patch_accounts_user(accounts_url, accounts_username, accounts_password, uuid, username)
  url = URI("#{accounts_url}/users/#{uuid}")
  payload = {
    "user_uuid": uuid,
    "user_email": email_or_null(username),
    "username": username
  }.to_json

  http = Net::HTTP::new(url.host, url.port)
  http.use_ssl = true
  request = Net::HTTP::Patch.new(url.request_uri, 'Content-Type' => 'application/json')
  request.basic_auth(accounts_username, accounts_password)
  request.body = payload

  response = http.request(request)
  response.code == "202"
end

def email_or_null(str)
  matches = str.match(URI::MailTo::EMAIL_REGEXP)

  if matches == nil
    return nil
  else
    return str
  end
end

token = get_uaac_token
scim = CF::UAA::Scim.new(uaac_url, token, skip_ssl_validation: true)
users = scim.all_pages(:user).map { |user| user_to_id_email_pair(user) }.to_h

users = users.delete_if { |_k, v| v.start_with?(*USER_PREFIX_BLACKLIST) }

## Add regex check for it a username being an email address
users.each do |uuid, name|
  existing = get_accounts_user(accounts_url, accounts_username, accounts_password, uuid)
  if existing == nil
    success = post_accounts_user(accounts_url, accounts_username, accounts_password, uuid, name)
    if success
      puts "posted user #{uuid}:#{name}:#{email_or_null(name) || 'null'}"
    else
      puts "failed to post user #{uuid}:#{name}:#{email_or_null(name) || 'null'}"
    end
  else
    success = patch_accounts_user(accounts_url, accounts_username, accounts_password, uuid, name)
    if success
      puts "patched user #{uuid}:#{name}:#{email_or_null(name) || 'null'}"
    else
      puts "failed to patch user #{uuid}:#{name}:#{email_or_null(name) || 'null'}"
    end
  end
end
