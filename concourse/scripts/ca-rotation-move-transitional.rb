#!/usr/bin/env ruby

require 'json'
require 'date'

require_relative './lib/credhub'
require_relative './lib/formatting'

credhub_server = ENV['CREDHUB_SERVER'] || raise("Must set $CREDHUB_SERVER env var")

expiry_days = ENV['EXPIRY_DAYS'].to_i
raise 'EXPIRY_DAYS must be set' if expiry_days.nil? || expiry_days.zero?
date_of_expiry = Date.today + expiry_days

api_url = "#{credhub_server}/v1"

puts "Getting certificates"
client = CredHubClient.new(api_url)
certs = client.certificates.reject { |c| c['name'].match?(/_old$/) }

puts "Finding CA certs"
ca_certs = certs.select { |c| c['name'] == c['signed_by'] }

ca_certs.each { |cert|
  cert_name = cert['name']

  puts "Getting active ca certs for #{cert_name}"
  versions = client.current_certificates(cert_name)

  if versions.length > 1
    puts "#{cert_name} has more than one active version"

    sorted_cas = versions
      .sort_by { |version| Date.parse(version['expiry_date']) }
      .reverse

    new_ca, old_ca, *_other_cas = sorted_cas

    if !old_ca['transitional'] && new_ca['transitional']

      puts "Version #{old_ca['id']} has an expiry date of #{old_ca['expiry_date']} and the transitional flag is set to #{old_ca['transitional']}"
      puts "Version #{new_ca['id']} has an expiry date of #{new_ca['expiry_date']} and the transitional flag is set to #{new_ca['transitional']}"
      puts "#{cert_name} has been regenerated"

      puts "Moving the transitional flag to the old CA certificate: #{old_ca['id']}"
      `credhub curl -p '#{api_url}/certificates/#{cert['id']}/update_transitional_version' -d '{\"version\": "#{old_ca['id']}"}' -X PUT`

      puts "Regenerating leaf certs"
      cert['signs'].each do |leaf|
        unless leaf['signs'].nil?
          puts "Can't regenerate #{leaf['name']} as it signs #{leaf['signs']}"
          next
        end

        puts "Regenerating #{leaf} signed by the #{cert_name}"
        `credhub regenerate -n '#{leaf}'`
      end
    end
  end
}

leaf_certs = certs.reject { |cert| ca_certs.include? cert }

puts "Checking leaf certs"

leaf_certs.select do |cert|
  cert_name = cert['name']

  puts "Getting active certs for #{cert_name}"
  versions = client.current_certificates(cert_name)

  if versions.length > 1
    puts "Skipping #{cert_name} as it has more than one active cert"
    next
  end

  expiry_date = Date.parse(versions.first['expiry_date'])
  expires_in = (expiry_date - Date.today).to_i

  if expiry_date <= date_of_expiry
    puts "#{cert_name} expires on #{expiry_date}. Expires in #{expires_in} days time. Regenerating #{cert_name}."
    `credhub regenerate -n "#{cert_name}"`
  else
    puts "#{cert_name} expires on #{expiry_date}. Expires in #{expires_in} days time. Doesn't need to be rotated."
  end
end
