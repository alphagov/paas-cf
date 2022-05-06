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

cronitor_smoke_test_monitor_code = ENV["CRONITOR_SMOKE_TEST_MONITOR_CODE"] || get_secret("cronitor/#{ENV['MAKEFILE_ENV_TARGET']}/smoke_test_monitor_code", "__NO_CRONITOR_SMOKE_TEST_MONITOR_CODE__")
cronitor_billing_smoke_test_monitor_code = ENV["CRONITOR_BILLING_SMOKE_TEST_MONITOR_CODE"] || get_secret("cronitor/#{ENV['MAKEFILE_ENV_TARGET']}/billing_smoke_test_monitor_code", "__NO_CRONITOR_SMOKE_TEST_MONITOR_CODE__")

upload_secrets(
  credhub_namespaces,
  "cronitor_smoke_test_monitor_code" => cronitor_smoke_test_monitor_code,
  "cronitor_billing_smoke_test_monitor_code" => cronitor_billing_smoke_test_monitor_code,
)
