#!/usr/bin/env ruby

# This code does the following:
# 1. Creates an Amazon Elastic Compute Cloud (Amazon EC2) security group.
# 2. Adds inbound rules to the security group.
# 3. Attaches the security group to an rds database.

require "aws-sdk-ec2"
require "aws-sdk-rds"
require "json"

# Return a previously created security group id using tags.
#
# @param ec2_client [Aws::EC2::Client] An initialized Amazon EC2 client.
# @param group_name [String] A previously created security group having tagged with Name.
# @return [String] The ID of the security group.
# @example
#   security_group_id(Aws::EC2::Client.new(region: 'eu-west-1'), group_name: 'my-security-group')
def security_group_id(ec2_client, group_name)
  existing_security_groups = ec2_client.describe_security_groups({
    filters: [
      { name: "tag:Name", values: [group_name] },
    ],
  })
  if existing_security_groups.security_groups.count.positive?
    existing_security_groups.security_groups.first.group_id
  end
end

# Return a previously created vpc id using tags.
#
# @param ec2_client [Aws::EC2::Client] An initialized Amazon EC2 client.
# @param vpc_name [String] A previously created vpc having tagged with Name.
# @return [String] The ID of the vpc.
# @example
#   vpc_id(Aws::EC2::Client.new(region: 'eu-west-1'), vpc_name: 'my-vpc')
def vpc_id(ec2_client, vpc_name)
  existing_vpcs = ec2_client.describe_vpcs({
    filters: [
      { name: "tag:Name", values: [vpc_name] },
    ],
  })
  if existing_vpcs.vpcs.count.positive?
    existing_vpcs.vpcs.first.vpc_id
  end
end

# Creates an Amazon Elastic Compute Cloud (Amazon EC2) security group.
#
# Prerequisites:
#
# - A VPC in Amazon Virtual Private Cloud (Amazon VPC).
#
# @param ec2_client [Aws::EC2::Client] An initialized
#   Amazon EC2 client.
# @param group_name [String] A name for the security group.
# @param description [String] A description for the security group.
# @param vpc_id [String] The ID of the VPC for the security group.
# @return [String] The ID of security group that was created.
# @example
#   puts create_security_group(
#     Aws::EC2::Client.new(region: 'eu-west-1'),
#     'my-security-group',
#     'This is my security group.',
#     'vpc-6713dfEX'
#   )
def create_security_group(
  ec2_client,
  group_name,
  description,
  vpc_id,
  dry_run
)
  security_group_id = security_group_id(ec2_client, group_name)

  if security_group_id.nil?
    begin
      security_group = ec2_client.create_security_group(
        group_name:,
        description:,
        vpc_id:,
        dry_run:,
      )
      security_group_id = security_group.group_id
      puts "Created security group '#{group_name}' with ID " \
        "'#{security_group_id}' in VPC with ID '#{vpc_id}'."

      ec2_client.create_tags({
        resources: [security_group_id],
      tags: [{ key: "Name", value: group_name }],
      })
    rescue Aws::EC2::Errors::DryRunOperation
      puts "Dryrun: create_security_group has not performed really"
      return "sg-abcdef00000000000"
    end
  end
  security_group_id
end

# Adds an inbound rule to an Amazon Elastic Compute Cloud (Amazon EC2)
# security group.
#
# Prerequisites:
#
# - The security group.
#
# @param ec2_client [Aws::EC2::Client] An initialized Amazon EC2 client.
# @param security_group_id [String] The ID of the security group.
# @param ip_protocol [String] The network protocol for the inbound rule.
# @param from_port [String] The originating port for the inbound rule.
# @param to_port [String] The destination port for the inbound rule.
# @param cidr_ip_range [String] The CIDR IP range for the inbound rule.
# @return [Bool] true if it succeeded, false if not.
# @example
#   exit 1 unless security_group_ingress_authorized?(
#     Aws::EC2::Client.new(region: 'eu-west-1'),
#     'sg-030a858e078f1b9EX',
#     'tcp',
#     '80',
#     '80',
#     '0.0.0.0/0'
#   )
def security_group_ingress_authorized?(
  ec2_client,
  security_group_id,
  ip_protocol,
  from_port,
  to_port,
  cidr_ip_range,
  dry_run
)
  if dry_run
    puts "Dryrun: authorize_security_group_ingress has not performed really"
    return true
  end
  ec2_client.authorize_security_group_ingress(
    group_id: security_group_id,
    ip_permissions: [
      {
        ip_protocol:,
        from_port:,
        to_port:,
        ip_ranges: [
          {
            cidr_ip: cidr_ip_range,
          },
        ],
      },
    ],
  )
  puts "Added inbound rule to security group '#{security_group_id}' for protocol " \
    "'#{ip_protocol}' from port '#{from_port}' to port '#{to_port}' " \
    "with CIDR IP range '#{cidr_ip_range}'."
  true
rescue StandardError => e
  puts "API response on adding inbound rule to security group: #{e.message}"
  false
end

# Check the existence of an rds instance with a specific id and return it
#
# @param rds_client [Aws::RDS::Client] An initialized Amazon RDS client.
# @param db_instance_identifier [String] A db instance identifier.
# @return [Aws::RDS::Types::DBInstance] the db instance found or nil.
# @example
#   db_instance(Aws::EC2::Client.new(region: 'eu-west-1'), db_instance_identifier: 'rds-mydatabase')
def db_instance(rds_client, db_instance_identifier)
  rds_client.describe_db_instances({
    db_instance_identifier:,
  }).db_instances.first
end

# Check if rds instance is aready binded with the security group.
#
# @param rds_client [Aws::RDS::Client] An initialized Amazon RDS client.
# @param db_instance_identifier [String] A db instance identifier.
# @param security_group_id [String] A previously created security group id.
# @return [Bool] true if found, false if not.
# @example
#   binded_rds_instance?(Aws::EC2::Client.new(region: 'eu-west-1'), db_instance_identifier: 'rds-mydatabase', security_group_id: 'sg-my-security-group')
def binded_rds_instance?(rds_client, db_instance_identifier, security_group_id)
  existing_rds_instance = db_instance(rds_client, db_instance_identifier)

  !existing_rds_instance&.vpc_security_groups&.find { |sg| sg.vpc_security_group_id == security_group_id }.nil?
end

# Bind a security group to a RDS instance.
#
# @param rds_client [Aws::RDS::Client] An initialized Amazon RDS client.
# @param db_instance_identifier [String] A db instance identifier.
# @param security_group_id [String] A previously created security group id.
# @return [Aws::RDS::Types::DBInstance] the db instance found or nil.
# @example
#   bind_security_group_to_rds_instance(Aws::EC2::Client.new(region: 'eu-west-1'), db_instance_identifier: 'rds-mydatabase', security_group_id: 'sg-my-security-group')
def bind_security_group_to_rds_instance(rds_client, db_instance_identifier, security_group_id, dry_run)
  existing_rds_instance = db_instance(rds_client, db_instance_identifier)
  if binded_rds_instance?(rds_client, db_instance_identifier, security_group_id)
    puts "DB instance #{db_instance_identifier} is already bound to #{security_group_id}"
    return existing_rds_instance
  end

  existing_vpc_security_groups = existing_rds_instance.vpc_security_groups.map(&:vpc_security_group_id).reject { |sg| sg == security_group_id }

  if dry_run
    puts "Dryrun: modify_db_instance has not performed really"
  else
    rds_client.modify_db_instance({
      db_instance_identifier:,
      vpc_security_group_ids: existing_vpc_security_groups << security_group_id,
      apply_immediately: true,
    })
  end
end

# Provide a usage text
def with_usage
  <<~USAGE
    Required ENV vars:
      PEER_NAME=<a peer name>
      DB_INSTANCE_ID=<a db instance id>
      DEPLOY_ENV=<provided from Makefile env target>
      AWS_DEFAULT_REGION=<provided from Makefile env target>
    Optional ENV vars:
      DRY=<true> # dry run no changes will be made - false by default
  USAGE
end

# Full run:
def run_me
  dry_run = ENV.fetch("DRY", nil)
  if dry_run.nil?
    dry_run = false
  else
    puts "Dryrun enabled, no changes will be applied to the security groups and db instances."
    dry_run = true
  end

  peer_name = ENV.fetch("PEER_NAME", nil)
  db_instance_identifier = ENV.fetch("DB_INSTANCE_ID", nil)
  vpc_name = ENV.fetch("DEPLOY_ENV", nil)
  region = ENV.fetch("AWS_DEFAULT_REGION", nil)

  if peer_name.nil? || db_instance_identifier.nil? || vpc_name.nil? || region.nil?
    puts "Error: Some required environmental variables are missing. Exiting"
    abort with_usage
  end

  peering_filename = "terraform/#{vpc_name}.vpc_peering.json"
  unless File.file?(peering_filename)
    puts "Error: #{peering_filename} not found in path. Exiting"
    abort with_usage
  end
  if File.zero?(peering_filename)
    puts "Error: #{peering_filename} is empty. Exiting"
    abort with_usage
  end

  peering_file_contents = File.read(peering_filename)
  begin
    peering_data = JSON.parse(peering_file_contents)
  rescue JSON::ParserError => e
    puts "Error: #{peering_filename} is unparsable. JSON.parse said:\n#{e}\nExiting"
    abort with_usage
  end

  peering_entry = peering_data.find { |x| x["peer_name"] == peer_name }
  if peering_entry.nil?
    puts "Error: Peer #{peer_name} was not found in #{peering_filename}. Exiting"
    abort with_usage
  end
  unless peering_entry.fetch("backing_service_routing", false)
    puts "Error: Peer #{peer_name} does not support backing_service_routing. Exiting"
    abort with_usage
  end

  cidr_ip_range = peering_entry.fetch("subnet_cidr", nil)
  if cidr_ip_range.nil?
    puts "Error: Could not find the subnet in #{peering_filename}. Exiting"
    abort with_usage
  end

  group_name = "for-peer-#{peer_name}-#{db_instance_identifier}"
  description = "Backing services security group for #{peer_name} peer connection assigned to #{db_instance_identifier} db instance"

  ec2_client = Aws::EC2::Client.new
  rds_client = Aws::RDS::Client.new

  vpc_id = vpc_id(ec2_client, vpc_name)

  db_instance = db_instance(rds_client, db_instance_identifier)
  if db_instance.nil?
    puts "Error: Could not find the db instance #{db_instance_identifier}. Exiting"
    abort with_usage
  end

  if db_instance.endpoint.port.nil?
    puts "Error: Could not identify port for the db instance #{db_instance_identifier}. Exiting"
    abort with_usage
  end
  endpoint_port = db_instance.endpoint.port

  puts "Attempting to create security group..."
  security_group_id = create_security_group(
    ec2_client,
    group_name,
    description,
    vpc_id,
    dry_run,
  )

  puts "Using #{security_group_id} security group id"

  security_group_ingress_authorized?(
    ec2_client,
    security_group_id,
    "tcp",
    endpoint_port,
    endpoint_port,
    cidr_ip_range,
    dry_run,
  )

  puts "Ingress for #{security_group_id} for port #{endpoint_port} authorised"

  puts "Attempting to attach security group #{security_group_id} to #{db_instance_identifier}"

  bind_security_group_to_rds_instance(rds_client, db_instance_identifier, security_group_id, dry_run)
  puts "DB instance #{db_instance_identifier} has #{security_group_id} security group attached."
end

run_me if $PROGRAM_NAME == __FILE__
