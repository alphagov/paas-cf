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

mailchimp_api_key = ENV["MAILCHIMP_API_KEY"] || get_secret("mailchimp/#{ENV['MAKEFILE_ENV_TARGET']}/api_key", "__NO_MAILCHIMP_API_KEY__")

upload_secrets(
  credhub_namespaces,
  "mailchimp_api_key" => mailchimp_api_key,
)
