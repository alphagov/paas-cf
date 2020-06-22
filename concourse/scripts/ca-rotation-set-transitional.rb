#!/usr/bin/env ruby

require "date"
require "json"

require_relative "./lib/credhub"
require_relative "./lib/formatting"

credhub_server = ENV["CREDHUB_SERVER"] || raise("Must set $CREDHUB_SERVER env var")

expiry_days = ENV["EXPIRY_DAYS"].to_i
raise "EXPIRY_DAYS must be set" if expiry_days.nil? || expiry_days.zero?

date_of_expiry = Date.today + expiry_days

api_url = "#{credhub_server}/v1"

client = CredHubClient.new(api_url)
ca_certs = client
  .certificates
  .reject { |c| c["name"].match?(/_old$/) }
  .select { |c| c["name"] == c["signed_by"] }

regenerated_certificate_names = []

ca_certs.select do |cert|
  cert_name = cert["name"]

  versions = client.current_certificates(cert_name)

  if versions.length > 1
    puts "#{cert_name.yellow} has multiple versions...#{'skipping'.green}"
    next
  end

  expiry_date = Date.parse(versions.first["expiry_date"])
  expires_in = (expiry_date - Date.today).to_i

  if expiry_date > date_of_expiry
    puts "#{cert_name.yellow} expires on #{expiry_date} (in #{expires_in} days)...#{'skipping'.green}"
    next
  end

  puts "#{cert_name.yellow} expires on #{expiry_date} (in #{expires_in} days)...#{'regenerating'.yellow}"
  client.regenerate_certificate_as_transitional(cert["id"])
  regenerated_certificate_names << cert_name
end

unless regenerated_certificate_names.empty?
  separator

  puts "The following certificates have been regenerated and marked as transitional:"

  regenerated_certificate_names.sort.each do |cert|
    puts cert.yellow
  end
end
