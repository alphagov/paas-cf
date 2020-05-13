#!/usr/bin/env ruby

require 'json'
require 'date'

require_relative './lib/formatting'

credhub_server = ENV['CREDHUB_SERVER'] || raise("Must set $CREDHUB_SERVER env var")

expiry_days = ENV['EXPIRY_DAYS'].to_i
raise 'EXPIRY_DAYS must be set' if expiry_days.nil? || expiry_days.zero?
date_of_expiry = Date.today + expiry_days

api_url = "#{credhub_server}/v1"

puts "Fetching the certificates"

certs = JSON.parse `credhub curl -p '#{api_url}/certificates'`

ca_certs = []

certs['certificates'].each { |cert|
  if cert['name'] == cert['signed_by']
    puts "Adding #{cert['name']} to list of ca certs"
    ca_certs.push(cert)
  end
}

ca_certs.select do |cert|
  cert_name = cert['name']

  puts "Getting active ca certs for #{cert_name}"
  resp = JSON.parse `credhub curl -p "#{api_url}/data?name=#{cert_name}&current=true"`
  expiry_date = Date.parse(resp['data'][0]['expiry_date'])
  expires_in = (expiry_date - Date.today).to_i

  if resp['data'].length > 1
    puts "Skipping #{cert_name} as it's in the middle of a rotation"
    next
  end

  if expiry_date <= date_of_expiry
    puts "#{cert_name} expires on #{expiry_date}. Expires in #{expires_in} days time. Regenerating #{cert_name}."
    `credhub curl -p "#{api_url}/certificates/#{cert['id']}/regenerate" -d '{\"set_as_transitional\": true}' -X POST`
  else
    puts "#{cert_name} expires on #{expiry_date}. Expires in #{expires_in} days time. Does not need rotating."
  end
end
