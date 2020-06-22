#!/usr/bin/env ruby
require "yaml"
require "English"

unless ARGV[0]
  puts "USAGE: #{$PROGRAM_NAME} /path/to/buildpacks.yml"
  exit 1
end

yaml = YAML.safe_load(File.read(ARGV[0].to_s))
yaml["buildpacks"].each do |bp|
  %w[name stack filename url sha].each do |testkey|
    if bp[testkey].nil? || bp[testkey].empty?
      raise "Key '#{testkey}' is missing or empty in buildpack configuration:\n#{bp}"
    end
  end
  system("./paas-cf/concourse/scripts/upload-buildpack.sh",
         bp["name"],
         bp["stack"].to_s,
         bp["filename"].to_s,
         bp["url"].to_s,
         bp["sha"].to_s,
         out: $stdout,
         err: :out)
  raise "Buildpack upload failed." unless $CHILD_STATUS.success?
end
