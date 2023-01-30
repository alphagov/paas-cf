#!/usr/bin/env ruby

require "English"
require "json"
require "yaml"
require_relative "./set_process_log_rate_limits"
require_relative "./val_from_yaml"

class QuotasSetter
  def initialize(manifest)
    @manifest = PropertyTree.new(manifest)
  end

  def apply!
    @manifest["instance_groups.api.jobs.cloud_controller_ng.properties.cc.quota_definitions"].each do |name, definition|
      create_update_quota(name, definition)
    end
  end

private

  def create_update_quota(name, definition)
    new_log_rate_limit = nil
    args = []
    definition.each do |param, value|
      case param
      when "memory_limit"
        args << "-m" << "#{value}M"
      when "total_services"
        args << "-s" << value.to_s
      when "total_routes"
        args << "-r" << value.to_s
      when "non_basic_services_allowed"
        args << (value ? "--allow-paid-service-plans" : "--disallow-paid-service-plans")
      when "log_rate_limit"
        new_log_rate_limit = value
        args << "-l" << (value.nil? ? "-1" : value.to_s)
      end
    end
    if existing_quotas.include?(name)
      ProcessLogRateLimitSetter.new(existing_quotas[name], new_log_rate_limit).apply!
      cf("update-quota", name, *args)
    else
      cf("create-quota", name, *args)
    end
  end

  def existing_quotas
    @existing_quotas ||= fetch_quotas
  end

  def fetch_quotas
    quotas_json = `cf curl -f '/v3/organization_quotas'`
    raise quotas_json unless $CHILD_STATUS.success?

    quotas = JSON.parse(quotas_json)
    Hash[quotas["resources"].map { |v| [v["name"], v] }]
  end

  def cf(*args)
    unless system("cf", *args)
      raise "Error: 'cf #{args.join(' ')}' exited #{$CHILD_STATUS.exitstatus}"
    end
  end
end

if $PROGRAM_NAME == __FILE__
  abort "Usage: #{$PROGRAM_NAME} /path/to/manifest.yml" unless ARGV.size == 1
  manifest = YAML.safe_load_file(ARGV[0], aliases: true)
  QuotasSetter.new(manifest).apply!
end
