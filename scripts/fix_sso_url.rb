#!/usr/bin/env ruby
# Temporary workaround for:
# - https://github.com/cloudfoundry/uaa/issues/562
# - https://github.com/cloudfoundry/uaa/pull/575

require 'uri'

REDIRECT_HOSTNAME = "login.#{ENV.fetch('SYSTEM_DNS_ZONE_NAME')}".freeze

puts "Paste URL:"
url = URI.parse(gets.chomp)

query = Hash[URI.decode_www_form(url.query)]
redirect_url = URI.parse(query.fetch('redirect_uri'))
redirect_url.path = "/#{redirect_url.host}#{redirect_url.path}"
redirect_url.host = REDIRECT_HOSTNAME
query['redirect_uri'] = redirect_url
url.query = URI.encode_www_form(query)

puts
puts "Corrected URL:"
puts url
