#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'upload_secrets.rb'

ENV['PASSWORD_STORE_DIR'] = ENV['AIVEN_PASSWORD_STORE_HIGH_DIR'] || ENV['AIVEN_PASSWORD_STORE_DIR']

begin
  credhub_namespace = ENV['CREDHUB_NAMESPACE'].split(',')
rescue NoMethodError # env var was not set
  credhub_namespace = ['/concourse/main/create-cloudfoundry', "/#{ENV['DEPLOY_ENV']}/#{ENV['DEPLOY_ENV']}"]
end

aiven_api_token = ENV['AIVEN_API_TOKEN'] || `pass "aiven.io/${MAKEFILE_ENV_TARGET}/api_token"`

upload_secrets(
  'config' => {
    'credhub_namespace' => credhub_namespace,
    's3_path' => "s3://gds-paas-#{ENV['DEPLOY_ENV']}-state/aiven-secrets.yml"
  },
  'secrets' => {
    'aiven_api_token' => aiven_api_token
  }
)
