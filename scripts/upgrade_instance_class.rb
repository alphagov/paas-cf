#!/usr/bin/env ruby

require "aws-sdk-rds"
require "logger"
require "singleton"
require "optparse"
require "rubygems/version"

class MyLogger
  include Singleton

  def initialize
    @logger = Logger.new($stdout)
    @logger.level = Logger::WARN
  end

  def log_info(message)
    @logger.info(message)
  end

  def log_warn(message)
    @logger.warn(message)
  end

  def log_fatal(message)
    @logger.fatal(message)
  end
end

def display_help
  puts "Usage: upgrade_instance_types.rb [options]"
  puts "Options:"
  puts " -h, --help   Display this help message"
  puts " --dry-run    Run the script in dry-run mode"
end

def closest_compatible_version(current_version, compatible_versions)
  current_version_obj = Gem::Version.new(current_version)
  compatible_versions = compatible_versions.map { |v| Gem::Version.new(v) }

  closest_version = nil
  min_difference = Float::INFINITY

  compatible_versions.each do |version|
    next if version <= current_version_obj

    difference = version.segments.map(&:to_i).zip(current_version_obj.segments.map(&:to_i)).map { |a, b| (a - b).abs }.sum

    if difference < min_difference
      min_difference = difference
      closest_version = version.to_s
    end
  end

  closest_version
end

# Upgrade the rds instance during the maintenance window with the new db instance class and potentially the new engine version if the new db instance class requires it
def modify_instance(rds_client, instance, target_class, the_engine_version, dry_run)
  unless dry_run
    rds_client.modify_db_instance({
      db_instance_identifier: instance.db_instance_identifier,
      db_instance_class: target_class,
      engine_version: the_engine_version,
      apply_immediately: false,
    })
  end

  MyLogger.instance.log_info("Update request submitted.")
end

def manage_instance_state(rds_client, instance)
  case instance.db_instance_status
  when /modifying|rebooting/
    MyLogger.instance.log_info("Instance #{instance.db_instance_identifier} is in a transitional state. Waiting for it to become available ...")
    rds_client.wait_until(:db_instance_available, db_instance_identifier: instance.db_instance_identifier)
    "available"
  when "available"
    MyLogger.instance.log_info("Instance #{instance.db_instance_identifier} is available.")
    "available"
  else
    MyLogger.instance.log_warn("Instance #{instance.db_instance_identifier} is in a state that can't be modified. Moving on ...")
    "abort"
  end
end

# Get the RDS instances
def get_instances(rds_client)
  instances = []
  next_token = nil

  loop do
    response = rds_client.describe_db_instances({
      max_records: 100,
      marker: next_token,
    })
    instances += response.db_instances
    next_token = response.marker

    break unless next_token
  end
  instances
end

def get_available_class_options(rds_client, instance)
  available_options = []
  next_token = nil

  loop do
    options_response = rds_client.describe_orderable_db_instance_options({
      engine: instance.engine,
      engine_version: instance.engine_version,
      max_records: 100,
      marker: next_token,
    })
    available_options += options_response.orderable_db_instance_options
    next_token = options_response.marker
    break unless next_token
  end
  available_options
end

def get_available_engine_version_options(rds_client, instance, target_class)
  available_versions = []
  next_token = nil

  loop do
    available_versions_response = rds_client.describe_orderable_db_instance_options({
      engine: instance.engine,
      db_instance_class: target_class,
      max_records: 100,
      marker: next_token,
    })
    available_versions += available_versions_response.orderable_db_instance_options
    next_token = available_versions_response.marker
    break unless next_token
  end
  available_versions
end

def process_instance(rds_client, instance, target_class, dry_run)
  # Get available instance class options for the current engine and engine version
  options = get_available_class_options(rds_client, instance)
  # Check if the target instance class is available for this engine and engine version
  compatible = options.any? do |option|
    option.db_instance_class == target_class
  end

  if compatible
    MyLogger.instance.log_info("Updating instance #{instance.db_instance_identifier} from #{instance.db_instance_class} to #{target_class} db_instance_class during maintenance window...")

    state = manage_instance_state(rds_client, instance)

    if state == "abort"
      "abort"
    else
      MyLogger.instance.log_warn("Updating instance #{instance.db_instance_identifier}.")

      modify_instance(rds_client, instance, target_class, instance.engine_version, dry_run)
    end
  else
    MyLogger.instance.log_info("Target instance class #{target_class} is not compatible with the current engine version.")
    MyLogger.instance.log_info("... trying to find a suitable engine upgrade.")

    engine_version_options = get_available_engine_version_options(rds_client, instance, target_class)

    compatible_versions = engine_version_options.map(&:engine_version)
    closest_version = closest_compatible_version(instance.engine_version, compatible_versions)

    if closest_version.nil?
      MyLogger.instance.log_warn("No compatible engine version upgrade found for target db instance #{target_class}.")
      return
    end

    comparison_result = Gem::Version.new(instance.engine_version) <=> Gem::Version.new(closest_version)

    if comparison_result >= 0
      MyLogger.instance.log_info("The current engine version is already at least as new as the closest available version.")
      return
    end

    state = manage_instance_state(rds_client, instance)

    if state == "abort"
      return
    end

    MyLogger.instance.log_info("Updating instance #{instance.db_instance_identifier} with class: #{target_class} and engine version: #{closest_version}.")
    modify_instance(rds_client, instance, target_class, closest_version, dry_run)
  end
end

def main(deploy_env, dry_run)
  instance_class_mapping = {
    "db.t2." => "db.t3.",
    "db.m4." => "db.m5.",
    "db.r4." => "db.r5.",
  }
  rds_client = Aws::RDS::Client.new

  instances = get_instances(rds_client)

  instances.each do |instance|
    instance.tag_list.each do |tag|
      if tag[:key] == "deploy_env" && tag[:value] == deploy_env
        # Is the instance class of interest?
        if instance_class_mapping.key? instance.db_instance_class[0..5]
          target_class = instance.db_instance_class.sub(instance.db_instance_class[0..5], instance_class_mapping.fetch(instance.db_instance_class[0..5]))
          process_instance(rds_client, instance, target_class, dry_run)
        else
          MyLogger.instance.log_info("Instance #{instance.db_instance_identifier} doesn't have a db instance class that needs replacing.")
        end
      end
    end
  end
rescue Aws::RDS::Errors::ServiceError => e
  MyLogger.instance.log_fatal("Caught #{e.class}, exiting")
end

ARGV << "-h" if ARGV.empty?

options = {}
parser = OptionParser.new { |opts|
  opts.banner = "Usage: ./upgrade_instance_class.rb [options]"

  opts.on("--env DEPLOY_ENV", String, "Specify the env this script should operate on") do |env|
    options[:env] = env
  end

  opts.on("--dry-run", TrueClass) do |dry_run|
    puts "Dry run? #{dry_run}"
    options[:dry_run] = true
  end

  opts.on_tail("-h", "--help", "Show help") do
    puts opts
    exit
  end
}.parse!
parser.parse!

main(options[:env], options[:dry_run]) if $PROGRAM_NAME == __FILE__
