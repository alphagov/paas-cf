#!/usr/bin/env ruby
require 'yaml'
require 'tempfile'
require 'openssl'

ALERT_DAYS = (ARGV[0] || "30").to_i

certs = YAML.safe_load(STDIN)

alert = false

certs.each { |variable, value|
  next unless value.is_a?(Hash) && value.has_key?('certificate')
  next if variable =~ /_old$/
  certificate = OpenSSL::X509::Certificate.new value['certificate']
  days_to_expire = ((certificate.not_after - Time.now) / (24 * 3600)).floor

  if days_to_expire > ALERT_DAYS
    puts "#{variable}: #{days_to_expire} days to expire. OK."
  else
    puts "#{variable}: #{days_to_expire} days to expire. ERROR! less than #{ALERT_DAYS} days."
    alert = true
  end
}

exit 1 if alert
