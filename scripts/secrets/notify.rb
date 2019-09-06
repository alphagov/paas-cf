#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'upload_secrets.rb'

ENV['PASSWORD_STORE_DIR'] = ENV['NOTIFY_PASSWORD_STORE_DIR']

begin
  credhub_namespace = ENV['CREDHUB_NAMESPACE'].split(',')
rescue NoMethodError # env var was not set
  credhub_namespace = ['/concourse/main/create-cloudfoundry', "/#{ENV['DEPLOY_ENV']}/#{ENV['DEPLOY_ENV']}"]
end

notify_api_key = ENV['NOTIFY_API_KEY'] || `pass "notify/${MAKEFILE_ENV_TARGET}/api_key"`

upload_secrets(
  'config' => {
    'credhub_namespace' => credhub_namespace,
    's3_path' => "s3://gds-paas-#{ENV['DEPLOY_ENV']}-state/notify-secrets.yml"
  },
  'secrets' => {
    'notify_api_key' => notify_api_key
  }
)
