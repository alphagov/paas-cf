#!/usr/bin/env ruby

require 'date'
require 'json'

require_relative './lib/credhub'
require_relative './lib/formatting'

credhub_server = ENV['CREDHUB_SERVER'] || raise("Must set $CREDHUB_SERVER env var")

api_url = "#{credhub_server}/v1"

puts "Getting certificates"
client = CredHubClient.new(api_url)
certs = client.certificates.reject { |c| c['name'].match?(/_old$/) }

puts "Finding CA certs"
ca_certs = certs.select { |c| c['name'] == c['signed_by'] }

ca_certs.each { |cert|
  puts "Getting active ca certs for #{cert['name']}"
  versions = client.current_certificates(cert['name'])

  if versions.length > 1
    puts "#{cert['name']} has more than one active version"

    sorted_cas = versions
      .sort_by { |version| Date.parse(version['expiry_date']) }
      .reverse

    new_ca, old_ca, *_other_cas = sorted_cas

    if old_ca['transitional'] && !new_ca['transitional']
      puts "Version #{old_ca['id']} has an expiry date of #{old_ca['expiry_date']} and the transitional flag is set to #{old_ca['transitional']}"
      puts "Version #{new_ca['id']} has an expiry date of #{new_ca['expiry_date']} and the transitional flag is set to #{new_ca['transitional']}"
      puts "Setting transitional flag for #{cert['name']} to null"
      `credhub curl -p '#{api_url}/certificates/#{cert['id']}/update_transitional_version' -d '{\"version\": null}' -X PUT`
    end
  end
}
