#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'upload_secrets.rb'

credhub_namespaces = [
  '/concourse/main/create-cloudfoundry',
]

csls_kinesis_destination_arn = `pass "cyber/${MAKEFILE_ENV_TARGET}/csls_kinesis_destination_arn"`

upload_secrets(
  credhub_namespaces,
  'cyber_csls_kinesis_destination_arn' => csls_kinesis_destination_arn,
)
