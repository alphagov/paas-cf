#!/usr/bin/env ruby
require 'optparse'
require 'yaml'

cf_secrets_file = nil
cf_secrets_file_updated = nil
vars_to_migrate = []

option_parser = OptionParser.new do |opts|
  opts.on('--cf-secrets FILE') do |file|
    cf_secrets_file = file
  end
  opts.on('--cf-secrets-updated FILE') do |file|
    cf_secrets_file_updated = file
  end
  opts.on('--var ORIG_NAME[:NEW_NAME]') do |var_mapping|
    orig_name = var_mapping.split(':')[0]
    new_name = var_mapping.split(':')[1] || orig_name
    vars_to_migrate << [orig_name, new_name]
  end
end
option_parser.parse!

cf_secrets = YAML.load_file(cf_secrets_file)

vars_to_migrate.each { |orig_name, new_name|
  if cf_secrets.has_key? orig_name
    cf_secrets[new_name] = cf_secrets[orig_name]
    cf_secrets.delete(orig_name)
  end
}

File.open(cf_secrets_file_updated, 'w') { |f|
  f.write cf_secrets.to_yaml
}
