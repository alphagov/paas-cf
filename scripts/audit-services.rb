#!/usr/bin/env ruby
# frozen_string_literal: true

script_path = File.absolute_path(__FILE__).sub!(Dir.pwd + "/", "")
File.open(File.expand_path("~/.paas-script-usage"), "a") { |f| f.puts script_path }

require "httparty"
require "optparse"
require "json"
require "yaml"
require "pp"

CF_OAUTH_TOKEN = `cf oauth-token`.freeze
API_ENDPOINT = `cf api`[/https.*$/].freeze

HEADERS = {
  Authorization: CF_OAUTH_TOKEN,
}.freeze

service_plan_guid = ARGV[0]

Filter = Struct.new(
  :org_regex,
  :space_regex,
  :plan_regex,
  :org_guid,
  :space_guid,
) do
  def unmarshal(input)
    data = JSON.parse(input)
    data.each do |key, value|
      self[key] = value
    rescue NameError
      $stderr.print("'#{key}' is not a valid filter term\n")
      raise
    end
    self
  end
end

filters = Filter.new

def parse_filter_json(input)
  filters = Filter.new
  filters.unmarshal(input)
end

op = OptionParser.new
op.accept(Filter) do |filter|
  parse_filter_json(filter)
end

op.on("-f", "--filter [JSON]", Filter, "JSON to Filter results") do |f|
  filters = f
end

op.parse!

if service_plan_guid.nil?
  puts <<-USAGE
  Usage:
  #{$PROGRAM_NAME} service-plan-guid [--filter 'valid-filter-json']

  Get service-plan-guid with:

  ```
  CF_TRACE=1 cf m | grep -A10 "elasticsearch"
  "label": "elasticsearch",
  ...
  "service_plans_url": "/v2/services/0c248093-6025-4d07-b559-ef647c2f58d1/service_plans", <<<<< SERVICE_PLAN_GUID = "0c248093-6025-4d07-b559-ef647c2f58d1"
  ```

  Filter JSON accepts the following:
  {
    "org_regex": REGEX_MATCHER,
    "space_regex": REGEX_MATCHER,
    "plan_regex": REGEX_MATCHER,
    "org_guid": GUID-OF-ORG,
    "space_guid": GUID-OF-SPACE
  }
  USAGE
  exit 1
end

def do_paginated_capi_request(uri) # rubocop:disable Metrics/MethodLength, Lint/UnneededDisable, Metrics/LineLength
  resources = []
  until uri.nil?
    req = HTTParty.get(
      "#{API_ENDPOINT}#{uri}",
      headers: HEADERS,
    )
    resp = req.parsed_response
    uri = resp["next_url"]
    if resp["resources"].nil?
      resources = resp["entity"]
    else
      resources.concat resp["resources"]
    end
  end
  resources
end
es_plans_req = do_paginated_capi_request(
  "/v2/service_plans?q=service_guid:#{service_plan_guid}",
)

plans = {}

es_plans_req.each do |plan| # rubocop:disable Metrics/BlockLength
  plan_name = plan["entity"]["name"]
  next unless plan_name \
      =~ Regexp.new(/#{filters.plan_regex}/)

  plan_instances_req = do_paginated_capi_request(
    plan["entity"]["service_instances_url"],
  )
  next if plan_instances_req.length.zero?

  plan_instances_req.each do |instance|
    name = instance["entity"]["name"]
    next unless instance["entity"]["space_guid"] \
      =~ Regexp.new(/#{filters.space_guid}/)

    owning_space_req = do_paginated_capi_request(
      instance["entity"]["space_url"],
    )
    owning_space_name = owning_space_req["name"]
    next unless owning_space_name \
      =~ Regexp.new(/#{filters.space_regex}/)

    next unless owning_space_req["organization_guid"] \
      =~ Regexp.new(/#{filters.org_guid}/)

    owning_org_url = owning_space_req["organization_url"]
    owning_guid_req = do_paginated_capi_request(
      owning_org_url,
    )
    owning_org_name = owning_guid_req["name"]
    next unless owning_org_name =~ Regexp.new(/#{filters.org_regex}/)

    plans[plan_name].nil? && plans[plan_name] = []
    plans[plan_name] << {
      "name" => name,
      "org_name" => owning_org_name,
      "space_name" => owning_space_name,
    }
  end
end

puts plans.to_yaml
