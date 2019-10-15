#!/usr/bin/env ruby
require 'openssl'
require 'json'
require 'date'

ALERT_DAYS = (ARGV[0] || "15").to_i

credhub_server = ENV['CREDHUB_SERVER'] || raise("Must set $CREDHUB_SERVER env var")

api_url = "#{credhub_server}/v1"

certs = JSON.parse `credhub curl -p '#{api_url}/certificates'`

alert = false

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

unless certs['certificates'].empty?
  certs['certificates'].each do |cert|
    next if cert['name'].include? "_old"

    active_certs = JSON.parse `credhub curl -p '#{api_url}/data?name=#{cert['name']}&current=true'`

    if (cert['name'] == cert['signed_by']) && (active_certs['data'].length > 1)
      _, current_cert = compare_ca_cert_versions(active_certs['data'])
      certificate = OpenSSL::X509::Certificate.new current_cert['value']['certificate']
    else
      certificate = OpenSSL::X509::Certificate.new active_certs['data'][0]['value']['certificate']
    end

    days_to_expire = ((certificate.not_after - Time.now) / (24 * 3600)).floor

    if days_to_expire > ALERT_DAYS
      puts "#{cert['name']}: #{days_to_expire} days to expire. OK."
    else
      puts "#{cert['name']}: #{days_to_expire} days to expire. ERROR! less than #{ALERT_DAYS} days."
      alert = true
    end

    unless certificate.extensions.find { |e| e.oid == 'subjectKeyIdentifier' }
      puts "#{cert['name']}: ERROR! Missing Subject Key Identifier"
      alert = true
    end
  end
end

exit 1 if alert
