#!/usr/bin/env ruby

require 'json'

credhub_server = ENV['CREDHUB_SERVER'] || raise("Must set $CREDHUB_SERVER env var")

api_url = "#{credhub_server}/v1"

puts "Getting certificates"

certs = JSON.parse `credhub curl -p '#{api_url}/certificates'`

ca_certs = []

puts "Finding CA certs"

certs['certificates'].each { |cert|
  if cert['name'] == cert['signed_by']
    puts "Adding #{cert['name']} to the list of CA certs"
    ca_certs.push(cert)
  end
}

def compare_ca_cert_versions(active_certs)
  if active_certs[0]['expiry_date'] == active_certs[1]['expiry_date']
    c = active_certs.sort_by { |version| version['version_created_at'] }
    if c[0]['version_created_at'] < c[1]['version_created_at']
      old_ca = c[0]
      new_ca = c[1]
    else
      old_ca = c[1]
      new_ca = c[0]
    end
  elsif active_certs[0]['expiry_date'] < active_certs[1]['expiry_date']
    old_ca = active_certs[0]
    new_ca = active_certs[1]
  else
    old_ca = active_certs[1]
    new_ca = active_certs[0]
  end

  [old_ca, new_ca]
end

ca_certs.each { |cert|
  puts "Getting active ca certs for #{cert['name']}"
  versions = JSON.parse `credhub curl -p '#{api_url}/data?name=#{cert['name']}&current=true'`
  if versions['data'].length > 1
    puts "#{cert['name']} has more than one active version"
    v = versions['data'].sort_by { |version| version['expiry_date'] }

    old_ca, new_ca = compare_ca_cert_versions(v)

    if old_ca['transitional'] && !new_ca['transitional']
      puts "Version #{old_ca['id']} has an expiry date of #{old_ca['expiry_date']} and the transitional flag is set to #{old_ca['transitional']}"
      puts "Version #{new_ca['id']} has an expiry date of #{new_ca['expiry_date']} and the transitional flag is set to #{new_ca['transitional']}"
      puts "Setting transitional flag for #{cert['name']} to null"
      `credhub curl -p '#{api_url}/certificates/#{cert['id']}/update_transitional_version' -d '{\"version\": null}' -X PUT`
    end
  end
}
