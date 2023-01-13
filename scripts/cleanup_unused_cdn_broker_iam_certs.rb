#!/usr/bin/env ruby

require "English"

script_path = File.absolute_path(__FILE__).sub!("#{Dir.pwd}/", "")
File.open(File.expand_path("~/.paas-script-usage"), "a") { |f| f.puts script_path }

require "json"

unless system "aws iam list-account-aliases > /dev/null"
  abort "Make sure you've configured your AWS keys"
end

all_certs = %x(aws iam list-server-certificates --query 'ServerCertificateMetadataList[?Path == `/cloudfront/prod-letsencrypt/`]')
abort all_certs unless $CHILD_STATUS.success?
all_cdn_certs = JSON.parse all_certs

dist_certs = `aws cloudfront list-distributions --query 'DistributionList.Items[].ViewerCertificate.Certificate'`
abort dist_certs unless $CHILD_STATUS.success?
cloudfront_used_certs = JSON.parse dist_certs

all_cdn_certs.each do |cert|
  if cloudfront_used_certs.include?(cert["ServerCertificateId"])
    puts "skipping used cert #{cert['ServerCertificateId']} #{cert['ServerCertificateName']}"
    next
  end

  puts "deleting unused cert #{cert['ServerCertificateId']} #{cert['ServerCertificateName']}"

  system "aws iam delete-server-certificate --server-certificate-name '#{cert['ServerCertificateName']}'"
end
