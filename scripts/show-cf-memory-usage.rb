#!/usr/bin/env ruby

require 'json'

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

orgs = JSON.load(`cf curl /v2/organizations`)['resources']
quotas = JSON.load(`cf curl /v2/quota_definitions`)['resources']

orgs_reserved_memory = 0
apps_reserved_memory = 0
allocated_services = 0
allocated_routes = 0

orgs.each { |org|
  quota_id = org['entity']['quota_definition_guid']
  quota_def = quotas.select { |quota| quota['metadata']['guid'] == quota_id }[0]
  orgs_reserved_memory += quota_def['entity']['memory_limit'].to_i
  allocated_services += quota_def['entity']['total_services'].to_i
  allocated_routes += quota_def['entity']['total_routes'].to_i
  org_id = org['metadata']['guid']
  org_apps_reserved_memory = JSON.load(`cf curl /v2/organizations/#{org_id}/memory_usage`)['memory_usage_in_mb']
  apps_reserved_memory += org_apps_reserved_memory.to_i
  puts "Memory reserved by apps in org '#{org['entity']['name']}': #{org_apps_reserved_memory} MB"
}

puts
puts "Allocated services: #{allocated_services}"
puts "Allocated routes: #{allocated_routes}"
puts
puts "Memory reserved by orgs: #{orgs_reserved_memory} MB (#{orgs_reserved_memory / 1024} GB)"
puts "Memory reserved by apps: #{apps_reserved_memory} MB (#{apps_reserved_memory / 1024} GB)"

apps_used_memory = 0
apps = JSON.load(`cf curl /v2/apps`)['resources']
apps.each { |app|
  apps_used_memory += app['entity']['memory'].to_i
}

puts
puts "Memory actually used by apps: #{apps_used_memory} (#{apps_used_memory / 1024} GB)"
puts
