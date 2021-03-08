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

cyber_slack_webhook_url = ENV["SLACK_WEBHOOK_URL"] || get_secret("gds.slack.com/cyber_slack_webhook_url")

upload_secrets(
  credhub_namespaces,
  "cyber_slack_webhook_url" => cyber_slack_webhook_url,
)
