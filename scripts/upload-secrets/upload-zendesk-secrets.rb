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

zendesk_api_token = ENV["ZENDESK_API_TOKEN"] || get_secret("zendesk/api_key")
zendesk_username = ENV["ZENDESK_USERNAME"] || get_secret("zendesk/api_user")

upload_secrets(
  credhub_namespaces,
  "zendesk_api_token" => zendesk_api_token,
  "zendesk_username" => zendesk_username,
)
