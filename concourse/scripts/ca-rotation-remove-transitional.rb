#!/usr/bin/env ruby

require "date"
require "json"
require "time"

require_relative "./lib/credhub"
require_relative "./lib/formatting"

credhub_server = ENV["CREDHUB_SERVER"] || raise("Must set $CREDHUB_SERVER env var")

api_url = "#{credhub_server}/v1"

client = CredHubClient.new(api_url)

ca_certs = client
  .certificates
  .reject { |c| c["name"].match?(/_old$/) }
  .select { |c| c["name"] == c["signed_by"] }

updated_certificate_names = []

ca_certs.each do |cert|
  cert_name = cert["name"]

  versions = client.current_certificates(cert_name)

  if versions.length <= 1
    puts "#{cert_name.yellow} does not have multiple versions...#{'skipping'.green}"
    next
  end

  sorted_cas = versions
    .sort_by { |version| Time.parse(version["expiry_date"]) }
    .reverse

  new_ca, old_ca, *_other_cas = sorted_cas

  unless sorted_cas.any? { |ca| ca["transitional"] }
    puts "#{cert_name.yellow} is not in transition...#{'skipping'.green}"
    next
  end

  if new_ca["transitional"]
    puts "#{cert_name.yellow} is in another transition step...#{'skipping'.green}"
    next
  end

  puts "Version #{old_ca['id']} has an expiry date of #{old_ca['expiry_date']} and the transitional flag is set to #{old_ca['transitional']}"
  puts "Version #{new_ca['id']} has an expiry date of #{new_ca['expiry_date']} and the transitional flag is set to #{new_ca['transitional']}"
  puts "#{cert_name.yellow} should not be transitional...#{'updating'.yellow}"
  client.update_certificate_transitional_version(cert["id"], nil)
  updated_certificate_names << cert_name
end

unless updated_certificate_names.empty?
  separator

  puts "The following certificates have been updated as non-transitional:"

  updated_certificate_names.sort.each do |cert|
    puts cert.yellow
  end
end
