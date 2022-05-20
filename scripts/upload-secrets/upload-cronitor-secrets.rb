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
prometheus_namespaces = ["/#{deploy_env}/prometheus"]

cronitor_smoke_test_monitor_code = ENV["CRONITOR_SMOKE_TEST_MONITOR_CODE"] || get_secret("cronitor/#{ENV['MAKEFILE_ENV_TARGET']}/smoke_test_monitor_code", "__NO_CRONITOR_SMOKE_TEST_MONITOR_CODE__")
cronitor_billing_smoke_test_monitor_code = ENV["CRONITOR_BILLING_SMOKE_TEST_MONITOR_CODE"] || get_secret("cronitor/#{ENV['MAKEFILE_ENV_TARGET']}/billing_smoke_test_monitor_code", "__NO_CRONITOR_BILLING_SMOKE_TEST_MONITOR_CODE__")
upload_secrets(
  credhub_namespaces,
  "cronitor_smoke_test_monitor_code" => cronitor_smoke_test_monitor_code,
  "cronitor_billing_smoke_test_monitor_code" => cronitor_billing_smoke_test_monitor_code,
)

cronitor_alertingwatchdog_heartbeat_code = ENV["CRONITOR_ALERTINGWATCHDOG_HEARTBEAT_CODE"] || get_secret("cronitor/#{ENV['DEPLOY_ENV']}/alertingwatchdog_heartbeat_code", "__NO_CRONITOR_ALERTINGWATCHDOG_HEARTBEAT_CODE__")
telemetry_api_key = ENV["TELEMETRY_API_KEY"] || get_secret("cronitor/telemetry_api_key", "__NO_CRONITOR_TELEMETRY_API_KEY__")

upload_secrets(
  prometheus_namespaces,
  "cronitor_alertingwatchdog_heartbeat_code" => cronitor_alertingwatchdog_heartbeat_code,
  "cronitor_telemetry_api_key" => telemetry_api_key,
)
