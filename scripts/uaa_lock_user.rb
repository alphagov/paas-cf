#!/usr/bin/env ruby

script_path = File.absolute_path(__FILE__).sub!(Dir.pwd + "/", "")
File.open(File.expand_path("~/.paas-script-usage"), "a") { |f| f.puts script_path }

require "optparse"
require "uaa"
require "ostruct"

STATE_MAP = {
  true => "unlocked",
  false => "locked",
}.freeze

def parse_args
  desired_active_state = false
  settings = OpenStruct.new(
    target: "",
    token: "",
    insecure: false,
  )

  optparse = OptionParser.new do |opts|
    opts.banner = <<EOS
Usage: uaa_lock_user.rb [options] USERNAME

You need to provide the following environment variables:

  TARGET=$(cf curl /v2/info | jq -r .token_endpoint)
  TOKEN=$(cf oauth-token)

EOS

    opts.on("--skip-ssl-validation", "Skip verification of the API endpoint. Not recommended!") do
      settings.insecure = true
    end

    opts.on("-u", "--unlock", "Unlock user") do
      desired_active_state = true
    end
  end
  optparse.parse!

  if ARGV.size != 1 || !ENV.include?("TARGET") || !ENV.include?("TOKEN")
    puts optparse
    exit 2
  end

  username = ARGV[0]
  settings.target = ENV.fetch("TARGET")
  settings.token = ENV.fetch("TOKEN")

  [username, desired_active_state, settings]
end

def update_user(username, active, uaac)
  query = { filter: "username eq '#{username}'" }
  users = uaac.all_pages(:user, query)

  if users.empty?
    abort "Username not found"
  elsif users.size > 1
    abort "Username is not unique"
  end
  user = users.first

  if user.fetch("active") != active
    user["active"] = active
    uaac.patch(:user, user)
  end

  "#{STATE_MAP.fetch(active)} #{username}"
end

username, active, settings = parse_args
uaac = CF::UAA::Scim.new(settings.target, settings.token, skip_ssl_validation: settings.insecure)
puts update_user(username, active, uaac)
