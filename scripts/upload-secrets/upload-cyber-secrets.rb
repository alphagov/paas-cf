#!/usr/bin/env ruby
# frozen_string_literal: true

script_path = File.absolute_path(__FILE__).sub!(Dir.pwd + "/", "")
File.open(File.expand_path("~/.paas-script-usage"), "a") { |f| f.puts script_path }

require_relative "upload_secrets.rb"

credhub_namespaces = [
  "/concourse/main/create-cloudfoundry",
]

secrets = {}

csls_kinesis_destination_arn = `pass "cyber/${MAKEFILE_ENV_TARGET}/csls_kinesis_destination_arn"`
secrets["cyber_csls_kinesis_destination_arn"] = csls_kinesis_destination_arn

secrets["csls_splunk_broker_url"] = "__STUB_csls_splunk_broker_url__"
secrets["csls_splunk_broker_username"] = "__STUB_csls_splunk_broker_username__"
secrets["csls_splunk_broker_password"] = "__STUB_csls_splunk_broker_password__"

if ENV["MAKEFILE_ENV_TARGET"].start_with?("prod")
  csls_splunk_broker_url = `pass "cyber/${MAKEFILE_ENV_TARGET}/csls_broker_url"`
  csls_splunk_broker_username = `pass "cyber/${MAKEFILE_ENV_TARGET}/csls_broker_username"`
  csls_splunk_broker_password = `pass "cyber/${MAKEFILE_ENV_TARGET}/csls_broker_password"`

  secrets["csls_splunk_broker_url"] = csls_splunk_broker_url
  secrets["csls_splunk_broker_username"] = csls_splunk_broker_username
  secrets["csls_splunk_broker_password"] = csls_splunk_broker_password
else
  puts "Skipping CSLS -> Splunk broker credentials because the environment \"#{ENV['MAKEFILE_ENV_TARGET']}\" does not start with \"prod\""
end

upload_secrets(
  credhub_namespaces,
  secrets,
)
