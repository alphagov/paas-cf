#!/usr/bin/env ruby

require 'optparse'
require 'yaml'
require 'open3'
require 'tmpdir'

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
  parser.on("--ca-add-ski", "Regenerate CA certs to include a Subject Key Identifier") { options[:ca_add_ski] = true }
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

def regenerate_cas(vars, certs)
  STDERR.puts "Regenerating CA certificates with Subject Key Identifiers"

  workdir = Dir.mktmpdir('rotate-cf-certs')

  vars.each do |var|
    next unless var.fetch("options", {}).fetch("is_ca", false)
    name = var.fetch("name")
    next unless certs.is_a?(Hash) && certs.has_key?(name)
    next if name.end_with?("_old")

    common_name = var.fetch("options").fetch("common_name")
    private_key = certs.fetch(name).fetch("private_key")

    STDERR.puts "Generating #{name} with common name #{common_name}"

    private_key_path = File.join(workdir, "private.key")
    File.open(private_key_path, 'w') { |file| file.write(private_key) }

    output = `certstrap init --expires "12 months" --common-name "#{common_name}" --passphrase "" --key "#{private_key_path}" --c "USA" -o "Cloud Foundry"`
    STDERR.puts output
    status = $?
    raise "certstrap exited #{status}" if status != 0

    cert = File.read("out/#{common_name}.crt")
    certs[name]["ca"] = cert
    certs[name]["certificate"] = cert

    `rm -rf out/#{common_name}.*`
  end

  if !workdir.nil?
    FileUtils.rm_rf(workdir)
  end

  certs
end

def rotate(manifest, certs, ca: false, leaf: false, delete: false, ca_add_ski: false)
  vars = manifest.fetch("variables").select { |v| v["type"] == 'certificate' }

  if delete
    return delete_old(vars, certs)
  end

  certs = rotate_cas(vars, certs) if ca
  certs = rotate_leafs(vars, certs) if leaf
  certs = regenerate_cas(vars, certs) if ca_add_ski

  certs
end

if $PROGRAM_NAME == __FILE__
  options = parse_args
  manifest = YAML.load_file(options.delete(:manifest))
  vars_store = YAML.load_file(options.delete(:vars_store))

  certs = rotate(manifest, vars_store, **options)
  puts certs.to_yaml
end
