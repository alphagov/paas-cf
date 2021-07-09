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

performance_data_exporter_credentials = ENV["GOOGLE_PERFORMANCE_DATA_EXPORTER_CREDS"] || get_secret("google/#{ENV['MAKEFILE_ENV_TARGET']}/service_account/performance_data_exporter_credentials")

upload_secrets(
  credhub_namespaces,
  "performance_data_exporter_credentials" => performance_data_exporter_credentials,
)
