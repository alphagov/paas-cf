#!/usr/bin/env ruby
# rubocop:disable Metrics/BlockLength

require "date"
require "json"
require "time"

require_relative "./lib/credhub"
require_relative "./lib/formatting"

credhub_server = ENV["CREDHUB_SERVER"] || raise("Must set $CREDHUB_SERVER env var")

expiry_days = ENV["EXPIRY_DAYS"].to_i
raise "EXPIRY_DAYS must be set" if expiry_days.nil? || expiry_days.zero?
date_of_expiry = Date.today + expiry_days

api_url = "#{credhub_server}/v1"

client = CredHubClient.new(api_url)
certs = client
  .certificates
  .reject { |c| c["name"].match?(/_old$/) }

ca_certs, leaf_certs = certs.partition { |c| c["name"] == c["signed_by"] }

transitional_certificate_names = []
regenerated_certificate_names = []

puts "Checking CA certs"
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

  unless new_ca["transitional"]
    puts "#{cert_name.yellow} does not need transitioning...#{'skipping'.green}"
    next
  end

  puts "#{cert_name.yellow} needs transitioning...#{'transitioning'.yellow}"
  client.update_certificate_transitional_version(cert["id"], old_ca["id"])
  transitional_certificate_names << cert_name

  cert["signs"].each do |leaf|
    unless leaf["signs"].nil?
      puts "Can't regenerate #{leaf['name'].red} as it signs #{leaf['signs'].red}"
      next
    end

    puts "#{leaf.blue} signed by #{cert_name.yellow}...#{'regenerating'.yellow}"
    client.regenerate_certificate(leaf)
    regenerated_certificate_names << leaf
  end
end

separator

puts "Checking leaf certs"
leaf_certs.select do |cert|
  cert_name = cert["name"]

  versions = client.current_certificates(cert_name)

  if versions.length > 1
    puts "#{cert_name.yellow} has more than one active cert...#{'skipping'.green}"
    next
  end

  expiry_date = Date.parse(versions.first["expiry_date"])
  expires_in = (expiry_date - Date.today).to_i

  if expiry_date > date_of_expiry
    puts "#{cert_name.yellow} expires on #{expiry_date} (in #{expires_in} days)...#{'skipping'.green}"
    next
  end

  if regenerated_certificate_names.include? cert_name
    puts "#{cert_name.yellow} already regenerated in this job...#{'skipping'.green}"
    next
  end

  puts "#{cert_name.yellow} expires on #{expiry_date} (in #{expires_in} days)...#{'regenerating'.yellow}"
  client.regenerate_certificate(cert_name)
  regenerated_certificate_names << cert_name
end

unless transitional_certificate_names.empty?
  separator

  puts "The following certificates have been transitioned:"
  transitional_certificate_names.sort.each do |cert|
    puts cert.yellow
  end
end

unless regenerated_certificate_names.empty?
  separator

  puts "The following certificates have been regenerated:"

  regenerated_certificate_names.sort.each do |cert|
    puts cert.yellow
  end
end

# rubocop:enable Metrics/BlockLength
