#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'upload_secrets.rb'

ENV['PASSWORD_STORE_DIR'] = ENV['AIVEN_PASSWORD_STORE_HIGH_DIR'] || ENV['AIVEN_PASSWORD_STORE_DIR']

deploy_env = ENV.fetch('DEPLOY_ENV')

credhub_namespaces = [
  '/concourse/main/create-cloudfoundry',
  "/#{deploy_env}/#{deploy_env}",
]

aiven_api_token = ENV['AIVEN_API_TOKEN'] || `pass "aiven.io/${MAKEFILE_ENV_TARGET}/api_token"`

upload_secrets(
  credhub_namespaces,
  'aiven_api_token' => aiven_api_token,
)
