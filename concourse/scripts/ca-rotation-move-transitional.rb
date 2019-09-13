#!/usr/bin/env ruby

require 'json'
require 'date'

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

    if !old_ca['transitional'] && new_ca['transitional']
      puts "Version #{old_ca['id']} has an expiry date of #{old_ca['expiry_date']} and the transitional flag is set to #{old_ca['transitional']}"
      puts "Version #{new_ca['id']} has an expiry date of #{new_ca['expiry_date']} and the transitional flag is set to #{new_ca['transitional']}"
      puts "#{cert['name']} has been regenerated"
      puts "Moving the transitional flag to the old CA certificate: #{old_ca['id']}"
      `credhub curl -p '#{api_url}/certificates/#{cert['id']}/update_transitional_version' -d '{\"version\": "#{old_ca['id']}"}' -X PUT`
      puts "Regenerating leaf certs"
      cert['signs'].each { |leaf|
        if !leaf['signs'].nil?
          puts "Can't regenerate #{leaf['name']} as it signs #{leaf['signs']}"
        else
          puts "Regenerating #{leaf} signed by the #{cert['name']}"
          `credhub regenerate -n '#{leaf}'`
        end
      }
    end
  end
}

leaf_certs = certs['certificates'].reject do |cert|
  ca_certs.include? cert
end

months_time = Date.today >> 1

puts "Checking leaf certs"

leaf_certs.select do |cert|
  puts "Getting active certs for #{cert['name']}"
  resp = JSON.parse `credhub curl -p "#{api_url}/data?name=#{cert['name']}&current=true"`
  expiry_date = Date.parse(resp['data'][0]['expiry_date'])
  expires_in = (expiry_date - Date.today).to_i
  if resp['data'].length > 1
    puts "Skipping #{cert['name']} as it has more than one active cert"
    next
  end
  if expiry_date < months_time
    puts "#{cert['name']} expires on #{expiry_date}. Expires in #{expires_in} days time. Regenerating #{cert['name']}."
    `credhub regenerate -n "#{cert['name']}"`
  else
    puts "#{cert['name']} expires on #{expiry_date}. Expires in #{expires_in} days time. Doesn't need to be rotated."
  end
end
