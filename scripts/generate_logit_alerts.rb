#!/usr/bin/env ruby

require "erb"
require "English"

def retrieve_from_paas_pass(path)
  result = `pass #{path}`.strip

  unless $CHILD_STATUS.success?
    raise "Failed to retrieve #{path} with `pass`."
  end

  result
end

deploy_env = ENV["DEPLOY_ENV"]

if deploy_env.nil?
  raise "$DEPLOY_ENV not set"
end

secret_env = ENV["MAKEFILE_ENV_TARGET"]

if secret_env.nil?
  raise "$MAKEFILE_ENV_TARGET not set"
end

logit_env = case secret_env
            when /^prod.*/
              "prod"
            else
              secret_env
            end

logit_account_uuid = retrieve_from_paas_pass("logit/account_id")
stack_id = retrieve_from_paas_pass("logit/#{logit_env}/stack_id")

logit_alert_url = "https://dashboard.logit.io/a/#{logit_account_uuid}/s/#{stack_id}/logs-settings/elastalert/viewrules"
pagerduty_service_key = retrieve_from_paas_pass("pagerduty/#{secret_env}/missing_logs_service_key")

pagerduty_client_name = "GOV.UK PaaS #{secret_env} Logit alerts"

warn "The following must be added to the logit config manually on the logit dashboard."
warn "Logit `#{logit_env}` stack alerting rules: #{logit_alert_url}"
warn "Either update the existing files or create new ones."

Dir.foreach("config/logit/alerts.d") do |file|
  next unless file.end_with?(".yaml.erb")

  template = ERB.new(File.read("config/logit/alerts.d/#{file}"))
  warn "Filename: #{deploy_env}__#{file.gsub(/\.erb$/, '')}"
  warn "Contents:\n\n"
  puts template.result(binding)
end
