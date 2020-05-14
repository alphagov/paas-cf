#!/usr/bin/env ruby

require 'date'
require 'json'

require_relative './lib/credhub'
require_relative './lib/formatting'

credhub_server = ENV['CREDHUB_SERVER'] || raise("Must set $CREDHUB_SERVER env var")

expiry_days = ENV['EXPIRY_DAYS'].to_i
raise 'EXPIRY_DAYS must be set' if expiry_days.nil? || expiry_days.zero?
date_of_expiry = Date.today + expiry_days

api_url = "#{credhub_server}/v1"

client = CredHubClient.new(api_url)
certs = client
  .certificates
  .reject { |c| c['name'].match?(/_old$/) }

ca_certs, leaf_certs = certs.partition { |c| c['name'] == c['signed_by'] }

transitional_certificate_names = []
regenerated_certificate_names = []

puts "Checking CA certs"
ca_certs.each do |cert|
  cert_name = cert['name']

  versions = client.current_certificates(cert_name)

  if versions.length <= 1
    puts "#{cert_name.yellow} does not have multiple versions...#{'skipped'.green}"
    next
  end

  sorted_cas = versions
    .sort_by { |version| Date.parse(version['expiry_date']) }
    .reverse

  new_ca, old_ca, *_other_cas = sorted_cas

  unless !old_ca['transitional'] && new_ca['transitional']
    puts "#{cert_name.yellow} does not need transitioning...#{'skipped'.green}"
    next
  end

  puts "Version #{old_ca['id']} has an expiry date of #{old_ca['expiry_date']} and the transitional flag is set to #{old_ca['transitional']}"
  puts "Version #{new_ca['id']} has an expiry date of #{new_ca['expiry_date']} and the transitional flag is set to #{new_ca['transitional']}"
  puts "#{cert_name} has been regenerated"

  puts "Moving the transitional flag to the old CA certificate: #{old_ca['id']}"
  `credhub curl -p '#{api_url}/certificates/#{cert['id']}/update_transitional_version' -d '{\"version\": "#{old_ca['id']}"}' -X PUT`
  transitional_certificate_names << cert_name

  puts "Regenerating leaf certs"
  cert['signs'].each do |leaf|
    unless leaf['signs'].nil?
      puts "Can't regenerate #{leaf['name'].red} as it signs #{leaf['signs'].red}"
      next
    end

    puts "#{leaf.yellow} signed by #{cert_name.yellow}...#{'regenerated'.yellow}"
    `credhub regenerate -n '#{leaf}'`
    regenerated_certificate_names << leaf
  end
end

separator

puts "Checking leaf certs"
leaf_certs.select do |cert|
  cert_name = cert['name']

  puts "Getting active certs for #{cert_name}"
  versions = client.current_certificates(cert_name)

  if versions.length > 1
    puts "#{cert_name.yellow} has more than one active cert...#{'skipped'.green}"
    next
  end

  expiry_date = Date.parse(versions.first['expiry_date'])
  expires_in = (expiry_date - Date.today).to_i

  if expiry_date > date_of_expiry
    puts "#{cert_name.yellow} expires on #{expiry_date} (in #{expires_in} days)...#{'skipped'.green}"
    next
  end

  puts "#{cert_name.yellow} expires on #{expiry_date} (in #{expires_in} days)...#{'regenerated'.yellow}"
  `credhub regenerate -n "#{cert_name}"`
  regenerated_certificate_names << cert_name
end

unless transitional_certificate_names.empty?
  separator

  puts 'The following certificates have been transitioned:'
  transitional_certificate_names.each do |cert|
    puts cert.yellow
  end
end

unless regenerated_certificate_names.empty?
  separator

  puts 'The following certificates have been regenerated:'

  regenerated_certificate_names.each do |cert|
    puts cert.yellow
  end
end
