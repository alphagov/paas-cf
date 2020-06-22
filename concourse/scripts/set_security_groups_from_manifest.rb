#!/usr/bin/env ruby

require "English"
require "tempfile"
require "json"
require "yaml"
require_relative "./val_from_yaml.rb"

class SecurityGroupsSetter
  def initialize(manifest)
    @manifest = PropertyTree.new(manifest)
  end

  def apply!
    cc_properties = @manifest["instance_groups.api.jobs.cloud_controller_ng.properties.cc"] || {}
    security_group_definitions = cc_properties["security_group_definitions"] || []
    security_group_definitions.each do |sg|
      create_update_sg(sg)
    end
    default_staging_security_groups = cc_properties["default_staging_security_groups"] || []
    default_staging_security_groups.each do |sg_name|
      cf("bind-staging-security-group", sg_name)
    end
    default_running_security_groups = cc_properties["default_running_security_groups"] || []
    default_running_security_groups.each do |sg_name|
      cf("bind-running-security-group", sg_name)
    end
  end

private

  def create_update_sg(sg)
    rules_file = Tempfile.new(["rules", ".json"])
    rules_file.write(sg.fetch("rules").to_json)
    rules_file.close
    if existing_security_groups.include?(sg.fetch("name"))
      cf("update-security-group", sg.fetch("name"), rules_file.path)
    else
      cf("create-security-group", sg.fetch("name"), rules_file.path)
    end
  ensure
    rules_file.unlink
  end

  def existing_security_groups
    @existing_security_groups ||= fetch_security_groups
  end

  def fetch_security_groups
    groups = []
    `cf security-groups`.each_line do |line|
      if line =~ /\A#\d+\s+(\S+)\s*/
        groups << $1
      end
    end
    groups
  end

  def cf(*args)
    unless system("cf", *args)
      raise "Error: 'cf #{args.join(' ')}' exited #{$CHILD_STATUS.exitstatus}"
    end
  end
end

if $PROGRAM_NAME == __FILE__
  abort "Usage: #{$PROGRAM_NAME} /path/to/manifest.yml" unless ARGV.size == 1
  manifest = YAML.load_file(ARGV[0])
  SecurityGroupsSetter.new(manifest).apply!
end
