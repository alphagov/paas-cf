#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'upload_secrets.rb'

ENV['PASSWORD_STORE_DIR'] = ENV['PAGERDUTY_PASSWORD_STORE_DIR']

begin
  credhub_namespace = ENV['CREDHUB_NAMESPACE'].split(',')
rescue NoMethodError # env var was not set
  credhub_namespace = ['/concourse/main/create-cloudfoundry', "/#{ENV['DEPLOY_ENV']}/#{ENV['DEPLOY_ENV']}"]
end

alertmanager_pagerduty_service_key = ENV['ALERTMANAGER_PAGERDUTY_SERVICE_KEY'] || `pass "pagerduty/${MAKEFILE_ENV_TARGET}/alertmanager_pagerduty_service_key"`

upload_secrets({
  'config' => {
    'credhub_namespace' => credhub_namespace,
    's3_path' => "s3://gds-paas-#{ENV['DEPLOY_ENV']}-state/pagerduty-secrets.yml"
  },
  'secrets' => {
    'alertmanager_pagerduty_service_key' => alertmanager_pagerduty_service_key
  }
})
