#!/usr/bin/env ruby

require 'yaml'

unless ARGV[0]
  puts "USAGE: #{$PROGRAM_NAME} /path/to/vars-store.yml"
  exit 1
end

def should_migrate?(_, val)
  return true if val['ca'] != ''
end


File.open(ARGV[0].to_s, 'r') do |f|
  vars = YAML.safe_load(f)
  vars_to_migrate = vars.select do |key, val|
    should_migrate?(key, val)
  end

  File.write('cf_vars_to_migrate.yml', vars_to_migrate.to_yaml)
end
