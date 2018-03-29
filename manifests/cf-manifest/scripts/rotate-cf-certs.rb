#!/usr/bin/env ruby

require 'optparse'
require 'yaml'

BLANK_CERT = {
  "ca" => "",
  "certificate" => "",
  "private_key" => "",
}.freeze

def parse_args
  options = {}
  parser = OptionParser.new
  parser.banner = "Usage: rotate-cf-certs.rb [options]"
  parser.on("--ca", "Rotate CA certs") { options[:ca] = true }
  parser.on("--leaf", "Rotate leaf certs") { options[:leaf] = true }
  parser.on("--delete", "Delete _old certificates") { options[:delete] = true }
  parser.on("--manifest MANIFEST", "BOSH manifest") { |v| options[:manifest] = v }
  parser.on("--vars-store VARS", "BOSH variable store") { |v| options[:vars_store] = v }
  parser.parse!

  if options[:vars_store].nil? || options[:manifest].nil?
    fail "--manifest and --vars-store arguments are mandatory"
  end

  options
end

def rotate_cas(vars, certs)
  vars.each do |var|
    next unless var.fetch("options", {}).fetch("is_ca", false)
    name = var.fetch("name")
    next unless certs.is_a?(Hash) && certs.has_key?(name)
    next if name.end_with?("_old")

    certs["#{name}_old"] = certs.delete(name)
  end

  certs
end

def rotate_leafs(vars, certs)
  vars.each do |var|
    next if var.fetch("options", {}).fetch("is_ca", false)
    name = var.fetch("name")
    next unless certs.is_a?(Hash) && certs.has_key?(name)
    next if name.end_with?("_old")

    certs.delete(name)
  end

  certs
end

def delete_old(vars, certs)
  vars.each do |var|
    next unless var.fetch("type", "") == "certificate"
    name = var.fetch("name")
    next unless name.end_with?("_old")

    certs[name] = BLANK_CERT
  end

  certs
end

def rotate(manifest, certs, ca: false, leaf: false, delete: false)
  vars = manifest.fetch("variables").select { |v| v["type"] == 'certificate' }

  if delete
    return delete_old(vars, certs)
  end

  certs = rotate_cas(vars, certs) if ca
  certs = rotate_leafs(vars, certs) if leaf

  certs
end

if $PROGRAM_NAME == __FILE__
  options = parse_args
  manifest = YAML.load_file(options.delete(:manifest))
  vars_store = YAML.load_file(options.delete(:vars_store))

  certs = rotate(manifest, vars_store, **options)
  puts certs.to_yaml
end
