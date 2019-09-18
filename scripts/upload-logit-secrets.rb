#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'upload_secrets.rb'

deploy_env = ENV.fetch('DEPLOY_ENV')

credhub_namespaces = [
  '/concourse/main/create-cloudfoundry',
  "/#{deploy_env}/#{deploy_env}",
]

logit_syslog_address = ENV['LOGIT_SYSLOG_ADDRESS'] || `pass "logit/${MAKEFILE_ENV_TARGET}/syslog_address"`
logit_syslog_port = ENV['LOGIT_SYSLOG_PORT'] || `pass "logit/${MAKEFILE_ENV_TARGET}/syslog_port"`
logit_ca_cert = ENV['LOGIT_CA_CERT'] || `pass "logit/${MAKEFILE_ENV_TARGET}/ca_cert"`
logit_elasticsearch_url = ENV['LOGIT_ELASTICSEARCH_URL'] || `pass "logit/${MAKEFILE_ENV_TARGET}/elasticsearch_url"`
logit_elasticsearch_api_key = ENV['LOGIT_ELASTICSEARCH_API_KEY'] || `pass "logit/${MAKEFILE_ENV_TARGET}/elasticsearch_api_key"`

upload_secrets(
  credhub_namespaces,
  'logit_syslog_address' => logit_syslog_address,
  'logit_syslog_port' => logit_syslog_port,
  'logit_ca_cert' => logit_ca_cert,
  'logit_elasticsearch_url' => logit_elasticsearch_url,
  'logit_elasticsearch_api_key' => logit_elasticsearch_api_key
)
