#!/usr/bin/env ruby

require "aws-sdk-iam"
require "optparse"

class PolicyNotFoundError < StandardError
end

def get_account_id
  sts_client = Aws::STS::Client.new
  response = sts_client.get_caller_identity
  response.account
end

def get_permissions_boundary_arn(iam_client, permissions_boundary_name)
  policies = iam_client.list_policies(scope: "Local", only_attached: false).policies

  permissions_boundary = policies.find { |policy| policy.policy_name == permissions_boundary_name }

  permissions_boundary&.arn
end

def get_identity_policy_arn(iam_client, identity_policy_name)
  account_id = get_account_id
  response = iam_client.get_policy({
    policy_arn: "arn:aws:iam::#{account_id}:policy/#{identity_policy_name}",
  })

  response.policy.arn
end

def add_permissions_boundary_to_user(iam_client, user, permissions_boundary_arn, dry_run)
  current_permissions_boundary = user.permissions_boundary&.permissions_boundary_arn
  if current_permissions_boundary.nil? || current_permissions_boundary != permissions_boundary_arn
    unless dry_run
      iam_client.put_user_permissions_boundary(
        user_name: user.user_name,
        permissions_boundary: permissions_boundary_arn,
      )
    end
    puts "Permissions_boundary added successfully to user #{user.user_name}."
  else
    puts "User #{user.user_name} already has the permissions_boundary."
  end
end

def add_identity_policy(iam_client, user, identity_policy_arn, dry_run)
  attached_policies = iam_client.list_attached_user_policies({ user_name: user.user_name }).attached_policies

  if attached_policies.none? { |policy| policy.policy_arn == identity_policy_arn }
    unless dry_run
      iam_client.attach_user_policy({
        user_name: user.user_name,
        policy_arn: identity_policy_arn,
      })
    end
    puts "Identity policy #{identity_policy_arn} successfully added to user #{user.user_name}."
  else
    puts "User #{user.user_name} already has the desired identity policy."
  end
end

def get_users(iam_client, env)
  paas_s3_broker_users = []
  next_token = nil

  loop do
    response = iam_client.list_users({ marker: next_token, max_items: 1000 })
    paas_s3_broker_batch = response.users.select do |user|
      guid_regex = /\b[a-f0-9]{8}\b-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-\b[a-f0-9]{12}\b/
      env_regex = /paas-s3-broker-#{env}-#{guid_regex}/
      user.user_name.match?(env_regex)
    end
    paas_s3_broker_users += paas_s3_broker_batch
    next_token = response.marker
    break unless next_token
  end

  paas_s3_broker_users
end

def main(env, identity_policy_name, boundary_policy_name, dry_run)
  iam_client = Aws::IAM::Client.new

  identity_policy_name = env + identity_policy_name

  permissions_boundary_arn = get_permissions_boundary_arn(iam_client, boundary_policy_name)
  identity_policy_arn = get_identity_policy_arn(iam_client, identity_policy_name)

  paas_s3_broker_users = get_users(iam_client, env)

  paas_s3_broker_users.each do |user|
    detailed_user = iam_client.get_user({ user_name: user.user_name }).user
    add_permissions_boundary_to_user(iam_client, detailed_user, permissions_boundary_arn, dry_run)
    add_identity_policy(iam_client, detailed_user, identity_policy_arn, dry_run)
  end
rescue PolicyNotFoundError => e
  puts "Error: #{e.message}"
  exit(1)
end

ARGV << "-h" if ARGV.empty?

options = {}
parser = OptionParser.new { |opts|
  opts.banner = "Usage: ./add_permissions_boundary_to_existing_s3_broker_users.rb [options]"

  opts.on("--env DEPLOY_ENV", String, "Specify the env this script should operate on") do |env|
    options[:env] = env
  end

  opts.on("--identity_policy_name IDENTITY_POLICY_NAME", String, "Specify the identity policy that will be added to the s3 broker users") do |identity_policy_name|
    options[:identity_policy_name] = identity_policy_name
  end

  opts.on("--boundary_policy_name BOUNDARY_POLICY_NAME", String, "Specify the boundary policy that will be added to the s3 broker users") do |boundary_policy_name|
    options[:boundary_policy_name] = boundary_policy_name
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

if options[:env].nil? || options[:identity_policy_name].nil? || options[:boundary_policy_name].nil?
  raise "--env, --identity_policy_name and --boundary_policy_name are mandatory"
end

main(options[:env], options[:identity_policy_name], options[:boundary_policy_name], options[:dry_run]) if $PROGRAM_NAME == __FILE__
