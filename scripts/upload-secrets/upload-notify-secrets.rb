#!/usr/bin/env ruby
# frozen_string_literal: true

script_path = File.absolute_path(__FILE__).sub!("#{Dir.pwd}/", "")
File.open(File.expand_path("~/.paas-script-usage"), "a") { |f| f.puts script_path }

require_relative "upload_secrets"

deploy_env = ENV.fetch("DEPLOY_ENV")

credhub_namespaces = [
  "/concourse/main/create-cloudfoundry",
  "/#{deploy_env}/#{deploy_env}",
]

notify_api_key = ENV["NOTIFY_API_KEY"] || get_secret("notify/#{ENV['MAKEFILE_ENV_TARGET']}/api_key")

upload_secrets(
  credhub_namespaces,
  "notify_api_key" => notify_api_key,
)
