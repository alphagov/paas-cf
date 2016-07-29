#!/usr/bin/env ruby
require 'cli'

bosh_cli = Bosh::Cli::Command::Base.new.director
deployments = bosh_cli.list_deployments

unless deployments.empty?
  warn("The following deployments must be deleted before destroying BOSH:")
  warn(deployments.map { |d| "- " + d.fetch('name') })
  abort
end
