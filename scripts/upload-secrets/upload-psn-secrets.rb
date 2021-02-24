#!/usr/bin/env ruby
# frozen_string_literal: true

script_path = File.absolute_path(__FILE__).sub!(Dir.pwd + "/", "")
File.open(File.expand_path("~/.paas-script-usage"), "a") { |f| f.puts script_path }

require_relative "upload_secrets.rb"

deploy_env = ENV.fetch("DEPLOY_ENV")

credhub_namespaces = [
  "/concourse/main/create-cloudfoundry",
  "/#{deploy_env}/#{deploy_env}",
]

vpc_endpoint = ENV["PSN_VPC_ENDPOINT"] || get_secret("gds/#{ENV['MAKEFILE_ENV_TARGET']}/psn_vpc_endpoint", "__NO_PSN_VPC_ENDPOINT__")

upload_secrets(
  credhub_namespaces,
  "psn_vpc_endpoint" => vpc_endpoint,
)
