#!/usr/bin/env ruby
require "openssl"
require "date"

require_relative "./lib/credhub"
require_relative "./lib/formatting"

ALERT_DAYS = (ARGV[0] || "15").to_i
CREDHUB_SERVER = ENV.fetch("CREDHUB_SERVER")
alert = false
api_url = "#{CREDHUB_SERVER}/v1"

separator

client = CredHubClient.new(api_url)
certs = client.certificates.reject { |c| c["name"].match?(/_old$/) }

transitional_certificate_names = []
expiring_certificate_names = []
invalid_certificate_names = []

certs.each do |cert|
  cert_name = cert["name"]
  live_certs = client.live_certificates(cert_name)

  live_certs.each do |live_cert|
    cred = client.credential(live_cert["id"])
    xcert = OpenSSL::X509::Certificate.new cred.dig("value", "certificate")

    days_to_expire = ((xcert.not_after - Time.now) / (24 * 3600)).floor
    alert = true unless days_to_expire > ALERT_DAYS

    transitional_status = live_cert["transitional"] ? "transitional".yellow : "non-transitional".blue
    expiring_status = days_to_expire > ALERT_DAYS ? "not expiring soon".green : "expiring soon".red

    cert_store = OpenSSL::X509::Store.new
    cert_store.add_cert(OpenSSL::X509::Certificate.new(cred.dig("value", "ca")))
    cert_is_valid = cert_store.verify(xcert)
    valid_status = cert_is_valid ? "valid".green : "invalid".red

    puts "#{cert_name.yellow} has #{days_to_expire} days to expire (#{transitional_status}) (#{expiring_status}) (#{valid_status})"

    expiring_certificate_names << cert_name unless days_to_expire > ALERT_DAYS
    transitional_certificate_names << cert_name if live_cert["transitional"]

    unless xcert.extensions.find { |e| e.oid == "subjectKeyIdentifier" }
      puts "#{cert_name}: ERROR! Missing Subject Key Identifier".red
      alert = true
    end

    unless cert_is_valid
      invalid_certificate_names << cert_name
      alert = true
    end
  end
end

unless transitional_certificate_names.empty?
  separator

  puts "The following certificates are transitional and are going to update instances:"

  transitional_certificate_names.each do |cert|
    puts cert.yellow
  end
end

unless expiring_certificate_names.empty?
  separator

  puts "The following certificates are expiring and require operator intervention:"

  expiring_certificate_names.each do |cert|
    puts cert.red
  end
end

unless invalid_certificate_names.empty?
  separator

  puts "The following certificates are invalid and require operator intervention:"

  invalid_certificate_names.each do |cert|
    puts cert.red
  end

  puts <<~HELP
    There are #{invalid_certificate_names.length} invalid certificates

    This is a problem and must be remedied manually

    You should:
    1. use the credhub CLI to get the relevant certificates
    2. debug why they are invalid using "openssl verify -verbose -issuer_checks -CAfile /path/to/ca /path/to/cert"
    3. confer with your pair about what to do
    4. delete/rotate/replace (possibly manually) them depending on the result of (3)
    5. re-run this job

    You may wish to refer to this previous incident: https://status.cloud.service.gov.uk/incidents/92gmvk51zw19

    Good luck
  HELP
end

separator

exit 1 if alert
