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

aiven_api_token = ENV["AIVEN_API_TOKEN"] || `pass "aiven.io/${MAKEFILE_ENV_TARGET}/api_token"`

aiven_prometheus_username    = ENV["AIVEN_PROMETHEUS_USERNAME"] || `pass "aiven.io/${MAKEFILE_ENV_TARGET}/prometheus_username"`
aiven_prometheus_password    = ENV["AIVEN_PROMETHEUS_PASSWORD"] || `pass "aiven.io/${MAKEFILE_ENV_TARGET}/prometheus_password"`
aiven_prometheus_endpoint_id = ENV["AIVEN_PROMETHEUS_PASSWORD"] || `pass "aiven.io/${MAKEFILE_ENV_TARGET}/prometheus_endpoint_id"`

upload_secrets(
  credhub_namespaces,
  "aiven_api_token" => aiven_api_token,
  "aiven_prometheus_username"    => aiven_prometheus_username,
  "aiven_prometheus_password"    => aiven_prometheus_password,
  "aiven_prometheus_endpoint_id" => aiven_prometheus_endpoint_id,
)
