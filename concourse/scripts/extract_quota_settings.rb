#!/usr/bin/env ruby
require 'json'
require 'yaml'

def usage()
  STDERR.puts "Usage CF_MANIFEST=/path/to/manifest.yml extract_quota_settings.rb /path/to/output_dir"
  exit 100
end

output_dir=ARGV[0]
usage unless output_dir
usage unless File.directory? output_dir

manifest_file = ENV.fetch("CF_MANIFEST", "")
usage if manifest_file.empty?

manifest = YAML.load_file(manifest_file)

quotas = manifest['properties']['cc']['quota_definitions'].keys
quotas.each do |quota|
  quotas_string = "export QUOTA_name='#{quota}'\n"
  manifest['properties']['cc']['quota_definitions'][quota].each { |k,v|
    quotas_string << "export QUOTA_#{k}='#{v}'\n"
  }
  File.write("#{output_dir}/#{quota}_quota.sh", quotas_string)
end
