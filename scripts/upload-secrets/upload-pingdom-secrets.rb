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

pingdom_api_token = ENV["PINGDOM_API_TOKEN"] || get_secret("pingdom.com/api_token", "__NO_PINGDOM_API_TOKEN__")

upload_secrets(
  credhub_namespaces,
  "pingdom_api_token" => pingdom_api_token,
)
