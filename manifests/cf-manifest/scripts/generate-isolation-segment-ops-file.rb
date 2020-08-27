#!/usr/bin/env ruby

require "English"
require "optparse"
require "yaml"

isolation_segment = YAML.safe_load(STDIN.read)

options = {}
OptionParser.new { |opts|
  opts.on(
    "-dPATH", "--isolation-segment-definition PATH",
    "Path to definition for isolation segment"
  ) do |d|
    options[:definition_path] = d
  end
}.parse! ARGV

abort "--isolation-segment-definition missing" if options[:definition_path].nil?

seg_def = YAML.safe_load(File.read(options[:definition_path]))

%w[
  isolation_segment_name
  number_of_cells
]
  .select { |var_name| seg_def[var_name].nil? }
  .each { |var_name| abort "Could not find #{var_name}" }

name = "diego-cell-iso-seg-#{seg_def['isolation_segment_name']}"
isolation_segment["name"] = name

isolation_segment["instances"] = seg_def["number_of_cells"]

unless seg_def["isolation_segment_size"].nil?
  vm_type = isolation_segment["vm_type"]

  memory_capacity = isolation_segment
    .fetch("jobs")
    .find { |job| job["name"] == "rep" }
    .dig("properties", "diego", "executor", "memory_capacity_mb")

  case seg_def["isolation_segment_size"]
  when "small"
    memory_capacity /= 2.0
    vm_type = "small_cell"
  else
    raise "Unknown isolation_segment_size #{seg_def['isolation_segment_size']}"
  end

  isolation_segment["vm_type"] = vm_type

  isolation_segment
    .fetch("jobs")
    .find { |job| job["name"] == "rep" }[
    "properties"][
    "diego"][
    "executor"][
    "memory_capacity_mb"] = memory_capacity
end

if seg_def["restricted_egress"]
  isolation_segment["jobs"] << {
    "name" => "coredns",
    "release" => "observability",
    "properties" => { "corefile" =>
      <<~COREFILE,
      .:53 {
        health :8054
        ready
        log
        prometheus :9153
        forward apps.internal 169.254.0.2:53
        bind 169.254.0.3
      }
      COREFILE
    },
  }

  isolation_segment
    .fetch("jobs")
    .find { |job| job["name"] == "silk-cni" }[
    "properties"][
    "dns_servers"] = ["169.254.0.3"]

  isolation_segment
    .fetch("jobs")
    .find { |job| job["name"] == "silk-cni" }[
    "properties"][
    "deny_networks"] = {
      "running" => %w[
        0.0.0.0/5
        8.0.0.0/7
        11.0.0.0/8
        12.0.0.0/6
        16.0.0.0/4
        32.0.0.0/3
        64.0.0.0/2
        128.0.0.0/1
      ],
    }

  isolation_segment["jobs"] << {
    "name" => "scripting",
    "release" => "generic-scripting",
    "properties" => { "scripting" => { "pre-start-script" =>
      <<~PRESTART,
      if ip addr show dev lo | grep -qF 169.254.0.3; then
        echo "IP Address 169.254.0.3/32 is already bound to dev lo...nothing to do"
      else
        echo "IP Address 169.254.0.3/32 is not bound to dev lo...binding"
        sudo ip addr add dev lo 169.254.0.3/32
        exit $?
      fi
      PRESTART
    } },
  }
end

isolation_segment
  .fetch("jobs")
  .find { |job| job["name"] == "rep" }[
  "properties"][
  "diego"][
  "rep"][
  "placement_tags"] = [seg_def["isolation_segment_name"]]

# We need to override bosh links to specify which the name of the
# VXLAN policy agent provided by this instance-group
isolation_segment
  .fetch("jobs")
  .find { |job| job["name"] == "vxlan-policy-agent" }["provides"] = {
    "vpa" => { "as" => "vpa-#{seg_def['isolation_segment_name']}" },
  }

%w[silk-daemon silk-cni].each do |consumer|
  isolation_segment
    .fetch("jobs")
    .find { |job| job["name"] == consumer }["consumes"] = {
      "vpa" => { "from" => "vpa-#{seg_def['isolation_segment_name']}" },
    }
end

puts [{
  "type"  => "replace",
  "path"  => "/instance_groups/-",
  "value" => isolation_segment,
}].to_yaml
