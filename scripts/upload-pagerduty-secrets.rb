#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'upload_secrets.rb'

ENV['PASSWORD_STORE_DIR'] = ENV['PAGERDUTY_PASSWORD_STORE_DIR']

deploy_env = ENV.fetch('DEPLOY_ENV')

credhub_namespaces = [
  '/concourse/main/create-cloudfoundry',
  "/#{deploy_env}/#{deploy_env}",
  "/#{deploy_env}/prometheus",
]

alertmanager_pagerduty_24_7_service_key = ENV['ALERTMANAGER_PAGERDUTY_24_7_SERVICE_KEY'] || `pass "pagerduty/${MAKEFILE_ENV_TARGET}/alertmanager_pagerduty_24_7_service_key"`
alertmanager_pagerduty_in_hours_service_key = ENV['ALERTMANAGER_PAGERDUTY_IN_HOURS_SERVICE_KEY'] || `pass "pagerduty/${MAKEFILE_ENV_TARGET}/alertmanager_pagerduty_in_hours_service_key"`

upload_secrets(
  credhub_namespaces,
  'alertmanager_pagerduty_24_7_service_key' => alertmanager_pagerduty_24_7_service_key,
  'alertmanager_pagerduty_in_hours_service_key' => alertmanager_pagerduty_in_hours_service_key,
)
