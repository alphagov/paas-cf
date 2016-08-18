#!/usr/bin/env ruby

require 'tempfile'
require 'json'
require 'yaml'

class SecurityGroupsSetter
  def initialize(manifest)
    @manifest = manifest
  end

  def apply!
    cc_properties = @manifest.fetch("properties").fetch("cc")
    cc_properties.fetch("security_group_definitions").each do |sg|
      create_update_sg(sg)
    end
    cc_properties.fetch("default_staging_security_groups").each do |sg_name|
      cf("bind-staging-security-group", sg_name)
    end
    cc_properties.fetch("default_running_security_groups").each do |sg_name|
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
      raise "Error: 'cf #{args.join(' ')}' exited #{$?.exitstatus}"
    end
  end
end

if __FILE__ == $0
  abort "Usage: #{$0} /path/to/manifest.yml" unless ARGV.size == 1
  manifest = YAML.load_file(ARGV[0])
  SecurityGroupsSetter.new(manifest).apply!
end
