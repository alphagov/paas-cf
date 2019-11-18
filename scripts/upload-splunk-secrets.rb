#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'upload_secrets.rb'

deploy_env = ENV.fetch('DEPLOY_ENV')

credhub_namespaces = [
  '/concourse/main/create-cloudfoundry',
  "/#{deploy_env}/#{deploy_env}",
]

splunk_key = ENV['SPLUNK_KEY'] || `pass "splunk/${MAKEFILE_ENV_TARGET}/key"`

upload_secrets(
  credhub_namespaces,
  'splunk_key' => splunk_key,
)
