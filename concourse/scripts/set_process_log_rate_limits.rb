#!/usr/bin/env ruby

require "English"
require "json"
require_relative "./lib/parsing"

class ProcessLogRateLimitSetter
  def initialize(organization_quota, new_limit)
    @organization_quota = organization_quota
    @new_limit = new_limit.nil? ? nil : parse_integer_quantity(new_limit)
  end

  def apply!
    current_quota_limit = @organization_quota["apps"]["log_rate_limit_in_bytes_per_second"]
    return if @new_limit == current_quota_limit
    return if @new_limit.nil?
    return unless current_quota_limit.nil? || @new_limit < current_quota_limit

    @organization_quota["relationships"]["organizations"]["data"].each do |org|
      org_guid = org["guid"]

      # calling this once-per-org should avoid the need to
      # handle proper paging
      processes_json = `cf curl -f '/v3/processes?per_page=5000&organization_guids=#{org_guid}'`
      abort processes_json unless $CHILD_STATUS.success?

      processes = JSON.parse(processes_json)
      unless processes["pagination"]["total_pages"] == 1
        raise "org #{org_guid} has >5000 processes: implement proper paging for this script"
      end

      processes["resources"].each do |process|
        current_limit = process["log_rate_limit_in_bytes_per_second"]
        next if current_limit > 0 && current_limit <= @new_limit

        process_guid = process["guid"]
        puts "Setting log_rate_limit_in_bytes_per_second for process #{process_guid} to #{@new_limit} (from #{current_limit})"

        resp = `cf curl -f '/v3/processes/#{process_guid}/actions/scale' -X POST -H "Content-type: application/json" -d '{"log_rate_limit_in_bytes_per_second": #{@new_limit}}'`
        abort resp unless $CHILD_STATUS.success?
      end
    end
  end
end

if $PROGRAM_NAME == __FILE__
  abort "Usage: #{$PROGRAM_NAME} ORG_QUOTA_NAME NEW_MAX_LIMIT" unless ARGV.size == 2
  quota_name = ARGV[0]
  new_max_limit = ARGV[1]

  quotas_json = `cf curl -f '/v3/organization_quotas?names=#{quota_name}'`
  abort "Failed to fetch organization quota #{ARGV[1]}: #{quotas_json}" unless $CHILD_STATUS.success?

  quotas = JSON.parse(quotas_json)["resources"]
  abort "Expected to find 1 organization_quota for name #{quota_name}, received #{quotas.size}" unless quotas.size == 1

  ProcessLogRateLimitSetter.new(quotas[0], new_max_limit).apply!
end
