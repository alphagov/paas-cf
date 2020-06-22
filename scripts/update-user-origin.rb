#!/usr/bin/env ruby

script_path = File.absolute_path(__FILE__).sub!(Dir.pwd + "/", "")
File.open(File.expand_path("~/.paas-script-usage"), "a") { |f| f.puts script_path }

require "json"

def usage
  <<~USAGE
    Usage: #{$0} user-guid desired-origin

    e.g. #{$0} 00000000-0000-0000-0000-000000000000 google

    This script requires:
    - uaac to be installed
    - a valid uaac token
    - the uaac target is set up correctly

    Set the UAA target with uaac target:

    > uaac target https://uaa.cloud.service.gov.uk

    You can get a token with the following command

    > uaac token client get admin -s <uaa-admin-token>

    Where <uaa-admin-token> can be retrieved with make prod credhub
  USAGE
end

user_guid, desired_origin = ARGV[0, 2]

abort usage if desired_origin.nil? || user_guid.nil?
abort usage unless user_guid.match?(/^\h{8}-\h{4}-\h{4}-\h{4}-\h{12}$/)

resp = `uaac curl '/Users/#{user_guid}' | awk '/RESPONSE BODY/,0'`
user = JSON.parse(resp.lines.map(&:chomp).drop(1).join(" "))

puts "Current user:"
pp user

user = user.keep_if { |k, _| %w[userName name emails].include?(k) }
user = user.update('origin': desired_origin)


command = <<~COMMAND.lines.map(&:chomp).join(" ")
  uaac curl '/Users/#{user_guid}'
  -X PUT
  -H 'If-Match: *'
  -H 'Content-Type: application/json'
  -H 'Accept: application/json'
  -d '#{user.to_json}'
COMMAND

puts "Updating user: #{user_guid} with origin #{desired_origin}"
puts `#{command}`
abort unless $?.success?

resp = `uaac curl '/Users/#{user_guid}' | awk '/RESPONSE BODY/,0'`
user = JSON.parse(resp.lines.map(&:chomp).drop(1).join(" "))

puts "Updated user:"
pp user
