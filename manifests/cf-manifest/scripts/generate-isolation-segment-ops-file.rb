#!/usr/bin/env ruby

require 'English'
require 'optparse'
require 'yaml'

isolation_segment = YAML.safe_load(STDIN.read)

options = {}
OptionParser.new do |opts|
  opts.on(
    '-dPATH', '--isolation-segment-definition PATH',
    'Path to definition for isolation segment'
  ) do |d|
    options[:definition_path] = d
  end
end.parse! ARGV

abort '--isolation-segment-definition missing' if options[:definition_path].nil?

seg_def = YAML.safe_load(File.read(options[:definition_path]))

%w[
  isolation_segment_name
  number_of_cells
]
  .select { |var_name| seg_def[var_name].nil? }
  .each { |var_name| abort "Could not find #{var_name}" }

name = "diego-cell-iso-seg-#{seg_def['isolation_segment_name']}"
isolation_segment['name'] = name

isolation_segment['instances'] = seg_def['number_of_cells']
isolation_segment['vm_type'] = seg_def['vm_type'] unless seg_def['vm_type'].nil?

isolation_segment
  .fetch('jobs')
  .find { |job| job['name'] == 'rep' }['properties']['diego']['rep']['placement_tags'] = [
    seg_def['isolation_segment_name']
  ]

# We need to override bosh links to specify which the name of the
# VXLAN policy agent provided by this instance-group
isolation_segment
  .fetch('jobs')
  .find { |job| job['name'] == 'vxlan-policy-agent' }['provides'] = {
    'vpa' => { 'as' => "vpa-#{seg_def['isolation_segment_name']}" }
  }

%w[silk-daemon silk-cni].each do |consumer|
isolation_segment
  .fetch('jobs')
  .find { |job| job['name'] == consumer }['consumes'] = {
    'vpa' => { 'from' => "vpa-#{seg_def['isolation_segment_name']}" }
  }
end

puts [{
  'type'  => 'replace',
  'path'  => '/instance_groups/-',
  'value' => isolation_segment
}].to_yaml
