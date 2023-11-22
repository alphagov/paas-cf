#!/usr/bin/env ruby

require "aws-sdk-iam"
require "optparse"

def get_permissions_boundary_arn(iam_client, permissions_boundary_name)
  policies = iam_client.list_policies(scope: "Local", only_attached: false).policies

  permissions_boundary = policies.find { |policy| policy.policy_name == permissions_boundary_name }

  permissions_boundary&.arn
end

def add_permissions_boundary_to_user(iam_client, username, permissions_boundary_arn, dry_run)
  user = iam_client.get_user(user_name: username).user
  current_permissions_boundary = user.permissions_boundary&.permissions_boundary_arn

  if current_permissions_boundary.nil? || current_permissions_boundary != permissions_boundary_arn
    unless dry_run
      iam_client.put_user_permissions_boundary(
          user_name: username,
          permissions_boundary: permissions_boundary_arn
      )
    end
    puts "Permissions_boundary added successfully to user #{username}."
  else
    puts "User #{username} already has the permissions_boundary."
  end
end

def main(env, policy_name, dry_run)
  iam_client = Aws::IAM::Client.new

  permissions_boundary_arn = get_permissions_boundary_arn(iam_client, policy_name)

  if permissions_boundary_arn.nil?
    puts "Permissions boundary policy with name #{policy_name} not found"
  else
    paas_s3_broker_users = iam_client.list_users.users.select { |user| user.user_name.start_with?("paas-s3-broker-#{env}") }

    paas_s3_broker_users.each do |user|
      add_permissions_boundary_to_user(iam_client, user.user_name, permissions_boundary_arn, dry_run)
    end
  end
end

ARGV << "-h" if ARGV.empty?

options = {}
parser = OptionParser.new { |opts|
  opts.banner = "Usage: ./add_permissions_boundary_to_existing_s3_broker_users.rb [options]"

  opts.on("--env DEPLOY_ENV", String, "Specify the env this script should operate on") do |env|
    options[:env] = env
  end

  opts.on("--policy_name POLICY_NAME", String, "Specify the policy that will be added to the s3 broker users") do |policy_name|
    options[:policy_name] = policy_name
  end

  opts.on("--dry-run", TrueClass, "Specify --dry-run if you want to run the script without changing anything") do |dry_run|
    puts "Dry run? #{dry_run}"
    options[:dry_run] = true
  end

  opts.on_tail("-h", "--help", "Show help") do
    puts opts
    exit
  end
}.parse!
parser.parse!

if options[:env].nil? || options[:policy_name].nil?
  raise "--env and --policy_name are mandatory"
end

main(options[:env], options[:policy_name], options[:dry_run]) if $PROGRAM_NAME == __FILE__
