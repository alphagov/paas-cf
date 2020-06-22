#!/usr/bin/env ruby
require "openssl"
require "date"

require_relative "./lib/credhub"
require_relative "./lib/formatting"

alert = false
CREDHUB_SERVER = ENV.fetch("CREDHUB_SERVER")
api_url = "#{CREDHUB_SERVER}/v1"

class CertificateHierarchy
  def initialize
    @cert_names = []
    @signs = {}
    @signed_by = {}
  end

  def add_edge(ca, cert)
    return if ca == cert

    @cert_names = @cert_names.push(ca).push(cert).uniq

    @signs[ca] ||= []
    @signs[ca] = @signs[ca].push(cert).uniq

    @signed_by[cert] = ca
  end

  def depth
    @cert_names.map { |c| depth_for_cert(c) }.max
  end

  def print
    root_certs.each { |root| print_cert(root, 0) }
  end

private

  def root_certs
    @cert_names.select { |c| @signed_by[c].nil? }
  end

  def depth_for_cert(cert)
    signer = @signed_by[cert]
    return 1 if signer.nil?

    depth_for_cert(signer) + 1
  end

  def print_cert(cert, indent)
    signed_certs = @signs[cert] || []

    if signed_certs.empty?
      puts((" " * indent) + cert.green)
    else
      puts((" " * indent) + cert.blue)
    end

    signed_certs.each { |c| print_cert(c, indent + 2) }
  end
end

separator

client = CredHubClient.new(api_url)
certs = client.certificates
hierarchy = CertificateHierarchy.new

certs.each do |cert|
  hierarchy.add_edge(cert["signed_by"], cert["name"])
end

hierarchy.print

separator

depth = hierarchy.depth

if depth != 2
  alert = true
  puts <<~MSG
    The depth of the certificate hierarchy is #{depth.to_s.red}

    Our certificate rotation process does not work for multiple levels of CAs

    It is likely that during our next certificate rotation something will go wrong
  MSG
else
  puts "The depth of the certificate hierarchy is #{depth.to_s.green} this is good."
end

exit 1 if alert
