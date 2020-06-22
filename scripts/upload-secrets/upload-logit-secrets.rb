#!/usr/bin/env ruby
# frozen_string_literal: true

script_path = File.absolute_path(__FILE__).sub!(Dir.pwd + "/", "")
File.open(File.expand_path("~/.paas-script-usage"), "a") { |f| f.puts script_path }

require_relative "upload_secrets.rb"

deploy_env = ENV.fetch("DEPLOY_ENV")

credhub_namespaces = [
  "/concourse/main/create-cloudfoundry",
  "/#{deploy_env}/#{deploy_env}",
]

stack_target = case ENV.fetch("MAKEFILE_ENV_TARGET")
               when /dev/
                 "dev"
               when /stg-lon/
                 "stg-lon"
               when /prod/
                 "prod"
               end

logit_syslog_address = ENV["LOGIT_SYSLOG_ADDRESS"] || `pass "logit/#{stack_target}/syslog_address"`
logit_syslog_port = ENV["LOGIT_SYSLOG_PORT"] || `pass "logit/#{stack_target}/syslog_port"`
logit_ca_cert = ENV["LOGIT_CA_CERT"] || `pass "logit/#{stack_target}/ca_cert"`
logit_elasticsearch_url = ENV["LOGIT_ELASTICSEARCH_URL"] || `pass "logit/#{stack_target}/elasticsearch_url"`
logit_elasticsearch_api_key = ENV["LOGIT_ELASTICSEARCH_API_KEY"] || `pass "logit/#{stack_target}/elasticsearch_api_key"`

upload_secrets(
  credhub_namespaces,
  "logit_syslog_address" => logit_syslog_address,
  "logit_syslog_port" => logit_syslog_port,
  "logit_ca_cert" => logit_ca_cert,
  "logit_elasticsearch_url" => logit_elasticsearch_url,
  "logit_elasticsearch_api_key" => logit_elasticsearch_api_key
)
