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
  vm_type
]
  .select { |var_name| seg_def[var_name].nil? }
  .each { |var_name| abort "Could not find #{var_name}" }

name = "diego-cell-iso-seg-#{seg_def['isolation_segment_name']}"
isolation_segment['name'] = name

isolation_segment['instances'] = seg_def['number_of_cells']
isolation_segment['vm_type'] = seg_def['vm_type']

isolation_segment
  .fetch('jobs')
  .find { |job| job['name'] == 'rep' }['properties']['diego']['rep']['placement_tags'] = [
    seg_def['isolation_segment_name']
  ]

puts [{
  'type'  => 'replace',
  'path'  => '/instance_groups/-',
  'value' => isolation_segment
}].to_yaml
