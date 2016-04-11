#!/usr/bin/env ruby
require 'json'
require 'yaml'

manifest_file = ENV.fetch("CF_MANIFEST")
manifest = YAML.load_file(manifest_file)
default = manifest['properties']['cc']['default_quota_definition']
puts "export QUOTA_DEFAULT=#{default}"

manifest['properties']['cc']['quota_definitions'][default].each { |k,v|
  puts "export QUOTA_#{k}='#{v}'"
}
