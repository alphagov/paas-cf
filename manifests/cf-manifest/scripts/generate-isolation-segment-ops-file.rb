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
  # When we restrict egress in an isolation segment, we presumably want to
  # prevent exfiltration of data via DNS requests.
  #
  # If we did not have a DNS masking service (in this case Coredns) then any
  # DNS request would go to BOSH DNS and then to the AWS VPC DNS service and
  # then to the internet
  #
  # An attacker could exfiltrade data by making a DNS lookup for
  # 42424242424242424242.attacker-controlled-domain.com
  # and logging DNS queries, (4242... is used as an example credit card number)
  #
  # We want apps to communicate with each other, so we need to allow
  # apps.internal DNS requests
  #
  # Unfortunately there is presently no way to distinguish between DNS server
  # during staging, and during runtime, as such we also need to allow DNS
  # requests for buildpacks.cloudfoundry.org, so that certain dependencies
  # provided by buildpacks (eg nginx package for staticfile buildpack) can be
  # downloaded during staging
  isolation_segment["jobs"] << {
    "name" => "coredns",
    "release" => "observability",
    "properties" => { "corefile" =>
      <<~COREFILE,
      (common) {
        health :8054
        ready
        log
        prometheus :9153
        bind 169.254.0.3
      }

      buildpacks.cloudfoundry.org {
        import common
        forward . 169.254.0.2:53
      }

      apps.internal {
        import common
        forward . 169.254.0.2:53
      }
      COREFILE
    },
  }

  # Localhost in an app container is not the same as localhost on the cell
  # In order for DNS requests made inside the container to reach a DNS server
  # on the host, it must have a non-loopback (localhost) IP address
  # 169.254/16 is defined in RFC 3927 as a range for link-local communication.
  #
  # The BOSH DNS agent listens on 169.254.0.2 for this reason.
  # Coredns listening on 169.254.0.3 is an arbitrary choice
  isolation_segment
    .fetch("jobs")
    .find { |job| job["name"] == "silk-cni" }[
    "properties"][
    "dns_servers"] = ["169.254.0.3"]

  # We are denying everything except 10/8
  # Some of these CIDR blocks look a little strange.
  # Look at the tests in spec/manifest/isolation_segment_spec.rb
  #
  # We are only denying egress during "running", not "always" or "staging",
  # which means the staging process has arbitrary egress, which is what we
  # want
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
