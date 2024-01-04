#!/usr/bin/env ruby

require "English"
require "cli/ui"
require "cli/ui/prompt"
require "json"
require "optparse"

# Helpers
def puts_ok(msg)
  puts "✅ #{msg}"
end

def puts_err(msg)
  puts "❌ #{msg}"
end

def puts_dry_run(msg)
  puts "🌵 (dry run) #{msg}"
end

def has_cf_session
  system "cf", "oauth-token", out: :close, err: :close
  $CHILD_STATUS.exitstatus == 0
end

def cf_api_get(path)
  # rubocop:disable CustomCops/MustCheckXStrExitstatus
  response = `cf curl "#{path}"`
  # rubocop:enable CustomCops/MustCheckXStrExitstatus

  if $CHILD_STATUS.exitstatus != 0
    raise "Error requesting #{path}"
  end

  JSON.parse(response)
end

def cf_api_delete(path)
  _ = `cf curl -X DELETE "#{path}"`
  $CHILD_STATUS.exitstatus == 0
end

def org_exists?(name)
  results = cf_api_get("/v3/organizations?names=#{name}")
  results["pagination"]["total_results"] == 1
end

def get_org_guid(name)
  org_list_results = cf_api_get("/v3/organizations?names=#{name}")
  org = org_list_results["resources"][0]
  org["guid"]
end

def org_suspended?(org_guid)
  org = cf_api_get("/v3/organizations/#{org_guid}")
  org["suspended"]
end

def num_apps(org_guid)
  apps = cf_api_get("/v3/apps?organization_guids=#{org_guid}&per_page=1")
  apps["pagination"]["total_results"]
end

def num_service_instances(org_guid)
  service_instances = cf_api_get("/v3/service_instances?organization_guids=#{org_guid}&per_page=1")
  service_instances["pagination"]["total_results"]
end

def num_spaces(org_guid)
  spaces = cf_api_get("/v3/spaces?organization_guids=#{org_guid}&per_page=1")
  spaces["pagination"]["total_results"]
end

def roles_in_org(org_guid)
  roles = cf_api_get("/v3/roles?organization_guids=#{org_guid}&per_page=5000")
  roles["resources"]
end

def lookup_users(user_guids)
  users = {}
  user_guids.each_slice(20) do |batch|
    guids_csv = batch.join(",")
    batch_users = cf_api_get("/v3/users?guids=#{guids_csv}&per_page=5000")
    users.merge! (batch_users["resources"].to_h { |usr| [usr["guid"], usr["username"]] })
  end
  users
end

def try_remove_role(role_guid)
  cf_api_delete("/v3/roles/#{role_guid}")
end

# Main
ARGV << "-h" if ARGV.empty?

options = {}
parser = OptionParser.new { |opts|
  opts.banner = "Usage: ./decommission_organisation.rb -o|--org ORG_NAME"

  opts.on("--org ORG_NAME", String, "Name of CloudFoundry organisation to decommission") do |org|
    options[:org] = org
  end

  opts.on("--dry-run", TrueClass) do |dry_run|
    puts "Dry run? #{dry_run}"
    options[:dry_run] = dry_run
  end

  opts.on_tail("-h", "--help", "Show this message") do
    puts opts
    exit
  end
}.parse!
parser.parse!

unless has_cf_session
  warn "Your environment must contain CloudFoundry credentials. Make sure you're logged into the environment in which the target org exists."
  exit 1
end

can_decommission = true

unless org_exists?(options[:org])
  puts_err "Organization '#{options[:org]}' does not exist in this region"
  exit 1
end
puts_ok "Organization exists"

org_guid = get_org_guid(options[:org])

if org_suspended?(org_guid)
  puts_ok("Suspended")
else
  puts_err("Not suspended")
  can_decommission = false
end

app_count = num_apps(org_guid)
if app_count == 0
  puts_ok("Apps: 0")
else
  puts_err("Apps: #{app_count}")
  can_decommission = false
end

svc_instance_count = num_service_instances(org_guid)
if svc_instance_count == 0
  puts_ok("Service instances: 0")
else
  puts_err("Service instances: #{svc_instance_count}")
  can_decommission = false
end

space_count = num_spaces(org_guid)
if space_count == 0
  puts_ok("Spaces: 0")
else
  puts_err("Spaces: #{space_count}")
  can_decommission = false
end

roles = roles_in_org(org_guid)
user_guids = roles.map { |r| r["relationships"]["user"]["data"]["guid"] }
users = lookup_users(user_guids)

if roles.empty?
  puts_err("Users: 0")
  can_decommission = false
else
  puts_ok("Users: #{users.length}")
  users.each do |guid, username|
    puts "\t🙂 #{username} (#{guid})"
  end
end

unless can_decommission
  puts "\n"
  puts "Cannot decommission org '#{options[:org]}'. It may have one or more apps, service instances, and spaces, or it may not be suspended"
  exit 1
end

continue = CLI::UI::Prompt.confirm("Continue to decomission org '#{options[:org]}'?")
unless continue
  exit 1
end

CLI::UI::StdoutRouter.enable
roles.each do |role|
  user_guid = role["relationships"]["user"]["data"]["guid"]
  username = users[user_guid]

  if !options[:dry_run]
    success = try_remove_role(role["guid"])
    if success
      puts_ok("Removed user '#{username}' (#{user_guid}) from role '#{role['type']}'")
    else
      puts_err("Removed user '#{username}' (#{user_guid}) from role '#{role['type']}'")
    end
  else
    puts_dry_run("Removing user '#{username}' (#{user_guid}) from role '#{role['type']}'")
  end
end
