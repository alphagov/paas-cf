#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'upload_secrets.rb'

ENV['PASSWORD_STORE_DIR'] = ENV['NOTIFY_PASSWORD_STORE_DIR']

deploy_env = ENV.fetch('DEPLOY_ENV')

credhub_namespaces = [
  '/concourse/main/create-cloudfoundry',
  "/#{deploy_env}/#{deploy_env}",
]

notify_api_key = ENV['NOTIFY_API_KEY'] || `pass "notify/${MAKEFILE_ENV_TARGET}/api_key"`

upload_secrets(
  credhub_namespaces,
  'notify_api_key' => notify_api_key,
)
