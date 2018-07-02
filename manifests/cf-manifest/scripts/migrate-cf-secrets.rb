#!/usr/bin/env ruby
require 'optparse'
require 'yaml'

cf_secrets_file = nil
cf_secrets_file_updated = nil
cf_vars_store_file = nil
cf_vars_store_file_updated = nil
vars_to_migrate = []

option_parser = OptionParser.new do |opts|
  opts.on('--cf-secrets FILE') do |file|
    cf_secrets_file = file
  end
  opts.on('--cf-secrets-updated FILE') do |file|
    cf_secrets_file_updated = file
  end
  opts.on('--cf-vars-store FILE') do |file|
    cf_vars_store_file = file
  end
  opts.on('--cf-vars-store-updated FILE') do |file|
    cf_vars_store_file_updated = file
  end
  opts.on('--var ORIG_NAME[:NEW_NAME]') do |var_mapping|
    orig_name = var_mapping.split(':')[0]
    new_name = var_mapping.split(':')[1] || orig_name
    vars_to_migrate << [orig_name, new_name]
  end
end
option_parser.parse!


cf_secrets = YAML.load_file(cf_secrets_file)
cf_secrets_updated = cf_secrets.clone
cf_vars_store = YAML.load_file(cf_vars_store_file)

vars_to_migrate.each { |orig_name, new_name|
  if cf_secrets.has_key? orig_name
    puts "INFO: migrating #{orig_name} to #{new_name}"
    if cf_secrets[orig_name].is_a?(Array)
      # Assume single element array
      cf_vars_store[new_name] = cf_secrets[orig_name][0]
    elsif cf_secrets[orig_name].is_a?(Hash)
      # Assume SSH key
      ssh_secret = cf_secrets[orig_name]
      ssh_secret["public_key_fingerprint"] = ssh_secret["public_fingerprint"]
      ssh_secret.delete("public_fingerprint")
      cf_vars_store[new_name] = ssh_secret
    else
      cf_vars_store[new_name] = cf_secrets[orig_name]
    end
    cf_secrets_updated.delete(orig_name)
  elsif cf_vars_store.has_key? new_name
    puts "INFO: #{orig_name} already migrated"
  elsif cf_vars_store.has_key?(orig_name) && (new_name != orig_name)
    puts "INFO: #{cf_vars_store_file} rename #{orig_name} => #{new_name}"

    cf_vars_store[new_name] = cf_secrets[orig_name]
    cf_vars_store.delete(orig_name)
  else
    puts "ERROR: #{cf_secrets_file} and #{cf_vars_store_file} do not contain #{orig_name}"
  end
}

File.open(cf_secrets_file_updated, 'w') { |f|
  f.write cf_secrets_updated.to_yaml
}
File.open(cf_vars_store_file_updated, 'w') { |f|
  f.write cf_vars_store.to_yaml
}
