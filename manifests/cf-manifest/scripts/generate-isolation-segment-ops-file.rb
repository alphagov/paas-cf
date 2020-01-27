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

unless seg_def['isolation_segment_size'].nil?
  vm_type = isolation_segment['vm_type']

  memory_capacity = isolation_segment
    .fetch('jobs')
    .find { |job| job['name'] == 'rep' }
    .dig('properties', 'diego', 'executor', 'memory_capacity_mb')

  case seg_def['isolation_segment_size']
  when 'small'
    memory_capacity /= 2.0
    vm_type = 'small_cell'
  else
    raise "Unknown isolation_segment_size #{seg_def['isolation_segment_size']}"
  end

  isolation_segment['vm_type'] = vm_type

  isolation_segment
    .fetch('jobs')
    .find { |job| job['name'] == 'rep' }[
    'properties'][
    'diego'][
    'executor'][
    'memory_capacity_mb'] = memory_capacity
end

if seg_def['restricted_egress']
  isolation_segment['jobs'] << {
    'name' => 'coredns',
    'release' => 'observability',
    'properties' => { 'corefile' =>
      <<~COREFILE
        .:10053 {
          health :10054
          ready
          log
          prometheus 0.0.0.0:9153
          forward apps.internal 169.254.0.2:53
        }
      COREFILE
    }
  }
end

isolation_segment
  .fetch('jobs')
  .find { |job| job['name'] == 'rep' }[
  'properties'][
  'diego'][
  'rep'][
  'placement_tags'] = [seg_def['isolation_segment_name']]

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
