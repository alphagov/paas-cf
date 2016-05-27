#!/usr/bin/env ruby
require 'cli'

# FIXME: Remove this debugging once it's no longer needed.
begin
  bosh_cli = Bosh::Cli::Command::Base.new.director
  deployments = bosh_cli.list_deployments
rescue
  require 'pp'
  puts "Environment:"
  pp ENV
  if ENV['BOSH_CONFIG']
    if File.exist?(ENV['BOSH_CONFIG'])
      puts "BOSH_CONFIG file contents:"
      puts File.read(ENV['BOSH_CONFIG'])
    else
      puts "BOSH_CONFIG references a non-existent file"
    end
  end

  # Re-raise the original exception
  raise
end

unless deployments.empty?
  warn("The following deployments must be deleted before destroying BOSH:")
  warn(deployments.map { |d| "- " + d.fetch('name') })
  abort
end
