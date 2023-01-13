#!/usr/bin/env ruby
# frozen_string_literal: true

script_path = File.absolute_path(__FILE__).sub!("#{Dir.pwd}/", "")
File.open(File.expand_path("~/.paas-script-usage"), "a") { |f| f.puts script_path }

require_relative "upload_secrets"

deploy_env = ENV.fetch("DEPLOY_ENV")

credhub_namespaces = [
  "/concourse/main/create-cloudfoundry",
  "/#{deploy_env}/#{deploy_env}",
  "/#{deploy_env}/prometheus",
]

alertmanager_pagerduty_24_7_service_key = ENV["ALERTMANAGER_PAGERDUTY_24_7_SERVICE_KEY"] || get_secret("pagerduty/#{ENV['MAKEFILE_ENV_TARGET']}/alertmanager_pagerduty_24_7_service_key")
alertmanager_pagerduty_in_hours_service_key = ENV["ALERTMANAGER_PAGERDUTY_IN_HOURS_SERVICE_KEY"] || get_secret("pagerduty/#{ENV['MAKEFILE_ENV_TARGET']}/alertmanager_pagerduty_in_hours_service_key")

upload_secrets(
  credhub_namespaces,
  "alertmanager_pagerduty_24_7_service_key" => alertmanager_pagerduty_24_7_service_key,
  "alertmanager_pagerduty_in_hours_service_key" => alertmanager_pagerduty_in_hours_service_key,
)
