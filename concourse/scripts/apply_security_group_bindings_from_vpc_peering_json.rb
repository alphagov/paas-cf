#!/usr/bin/env ruby

require "json"

if ARGV.empty?
  puts "Error: missing peering json file in arg 1"
  puts "Usage: #{$PROGRAM_NAME} /path/to/env_vpc_peering_file.json [--dry-run]"
  exit(1)
end

unless File.file?(ARGV[0])
  puts "Skipping as peering json file does not exist"
  exit(0)
end

if ARGV[1] == "--dry-run"
  dry_run = true
end

config_data = File.read(ARGV[0])

begin
  config = JSON.parse(config_data)
rescue JSON::ParserError => e
  abort "Error parsing JSON file: #{e.message}"
end

config.each_with_index do |peer, peer_index|
  peer_name = peer["peer_name"]
  bindings = peer["bindings"]
  if peer_name.nil? || peer_name.empty?
    puts "Error in JSON data at peer index #{peer_index}: Missing 'peer_name'."
    exit(1)
  end
  if bindings.nil? || bindings.empty?
    puts "Skipping at peer index #{peer_index}: Missing 'bindings'."
    next
  end
  sec_group_name = "vpc_peer_#{peer_name}"
  bindings&.each do |binding|
    org_name = binding["org_name"]
    all_spaces = binding["all_spaces"]
    spaces = binding["spaces"]
    if org_name.nil? || org_name.empty?
      puts "Error in JSON data at peer index #{peer_index}: Missing 'org_name' in bindings."
      exit(1)
    end
    if all_spaces == true
      command = "cf bind-security-group #{sec_group_name} #{org_name}"
      if dry_run
        puts "dry-run: #{command}"
      else
        success = system(command)
        unless success
          puts "Error executing command: #{command}"
          exit(1)
        end
      end
    else
      if spaces.nil? || spaces.empty?
        puts "Error in JSON data at peer index #{peer_index}: Missing 'spaces' key when 'all_spaces' is false."
        exit(1)
      end
      spaces&.each do |space|
        command = "cf bind-security-group #{sec_group_name} #{org_name} --space #{space}"
        if dry_run
          puts "dry-run: #{command}"
        else
          success = system(command)
          unless success
            puts "Error executing command: #{command}"
            exit(1)
          end
        end
      end
    end
  end
end
