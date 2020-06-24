#!/usr/bin/env ruby
# frozen_string_literal: true

script_path = File.absolute_path(__FILE__).sub!(Dir.pwd + "/", "")
File.open(File.expand_path("~/.paas-script-usage"), "a") { |f| f.puts script_path }

require_relative "upload_secrets.rb"

credhub_namespaces = [
  "/concourse/main/create-cloudfoundry",
]

csls_kinesis_destination_arn = `pass "cyber/${MAKEFILE_ENV_TARGET}/csls_kinesis_destination_arn"`

upload_secrets(
  credhub_namespaces,
  "cyber_csls_kinesis_destination_arn" => csls_kinesis_destination_arn,
)
