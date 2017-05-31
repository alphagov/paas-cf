#!/usr/bin/env ruby

require 'json'
require 'uri'

datadog_url = URI("https://app.datadoghq.com/metric/explorer")
datadog_url.query = URI.encode_www_form(
  exp_agg: "sum",
  exp_metric: "system.mem.total",
  exp_scope: "bosh-job:cell,bosh-deployment:#{ENV.fetch('DEPLOY_ENV')}",
)

config_path = File.expand_path('~/.cf/config.json')
if File.exist?(config_path)
  current_target = JSON.load(File.read(config_path))["Target"]
  if current_target != ENV['API_ENDPOINT']
    puts
    puts "WARNING: This script runs against the environment you are currently logged into, not the one you are targetting."
    puts
    puts "You are currently logged into: #{current_target}"
    puts "You are currently targetting: #{ENV['API_ENDPOINT']}"
    puts
    puts "This might not do what you expect. To run against the environment you indicated, please:"
    puts
    puts "1. `cf api #{current_target}`"
    puts "2. `cf login`"
    puts "3. Run this command again."
    puts
    puts "If you are sure you want to continue, press enter, or ctrl-c to abort."
    puts
    gets
  end
end

# Fetch all resources from the path, iterating over all pages of responses.
def cf_curl_all_resources(path)
  page = JSON.load(`cf curl "#{path}"`)
  results = page['resources']
  until page['next_url'].nil?
    page = JSON.load(`cf curl "#{page['next_url']}"`)
    results += page['resources']
  end
  results
end

def format_memory(amount)
  "#{amount} MB (#{(amount.to_f / 1024).round(1).to_s.chomp('.0')} GB)"
end

orgs = cf_curl_all_resources('/v2/organizations')
quotas = cf_curl_all_resources('/v2/quota_definitions')

orgs_reserved_memory = 0
apps_reserved_memory = 0
allocated_services = 0
allocated_routes = 0

orgs.each { |org|
  quota_id = org['entity']['quota_definition_guid']
  quota_def = quotas.select { |quota| quota['metadata']['guid'] == quota_id }[0]

  org_memory_quota = quota_def['entity']['memory_limit'].to_i
  orgs_reserved_memory += org_memory_quota if org_memory_quota > 0

  allocated_services += quota_def['entity']['total_services'].to_i
  allocated_routes += quota_def['entity']['total_routes'].to_i

  org_id = org['metadata']['guid']
  org_apps_reserved_memory = JSON.load(`cf curl /v2/organizations/#{org_id}/memory_usage`)['memory_usage_in_mb'].to_i
  apps_reserved_memory += org_apps_reserved_memory

  puts "Org '#{org['entity']['name']}': #{format_memory(org_apps_reserved_memory)} reserved by apps / #{format_memory(org_memory_quota)} quota"
}

# ADR017 requires capacity for 50% of orgs_reserved_memory in the case of a region failure.
# So we require 50% * 3/2 when all 3 regions are running.
required_cell_memory = (orgs_reserved_memory / 2) * 3 / 2

puts
puts "Allocated services: #{allocated_services}"
puts "Allocated routes: #{allocated_routes}"
puts
puts "Memory reserved by orgs: #{format_memory(orgs_reserved_memory)}"
puts "Memory reserved by apps: #{format_memory(apps_reserved_memory)}"
puts
puts "Total cell memory required to meet ADR017: #{format_memory(required_cell_memory)}"
puts "Compare this against: #{datadog_url}"
