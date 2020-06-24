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

google_oauth_client_id = ENV["GOOGLE_OAUTH_CLIENT_ID"] || `pass "google/${MAKEFILE_ENV_TARGET}/oauth/client_id"`
google_oauth_client_secret = ENV["GOOGLE_OAUTH_CLIENT_SECRET"] || `pass "google/${MAKEFILE_ENV_TARGET}/oauth/client_secret"`
admin_google_oauth_client_id = ENV["ADMIN_GOOGLE_OAUTH_CLIENT_ID"] || `pass "google/${MAKEFILE_ENV_TARGET}/oauth/admin_client_id"`
admin_google_oauth_client_secret = ENV["ADMIN_GOOGLE_OAUTH_CLIENT_SECRET"] || `pass "google/${MAKEFILE_ENV_TARGET}/oauth/admin_client_secret"`
grafana_auth_google_client_id = ENV["GRAFANA_AUTH_GOOGLE_CLIENT_ID"] || `pass "google/${MAKEFILE_ENV_TARGET}/oauth/grafana_client_id"`
grafana_auth_google_client_secret = ENV["GRAFANA_AUTH_GOOGLE_CLIENT_SECRET"] || `pass "google/${MAKEFILE_ENV_TARGET}/oauth/grafana_client_secret"`
google_paas_admin_client_id = ENV["GOOGLE_PAAS_ADMIN_CLIENT_ID"] || `pass "google/${MAKEFILE_ENV_TARGET}/oauth/paas_admin_client_id"`
google_paas_admin_client_secret = ENV["GOOGLE_PAAS_ADMIN_CLIENT_SECRET"] || `pass "google/${MAKEFILE_ENV_TARGET}/oauth/paas_admin_client_secret"`

upload_secrets(
  credhub_namespaces,
  "google_oauth_client_id" => google_oauth_client_id,
  "google_oauth_client_secret" => google_oauth_client_secret,
  "admin_google_oauth_client_id" => admin_google_oauth_client_id,
  "admin_google_oauth_client_secret" => admin_google_oauth_client_secret,
  "grafana_auth_google_client_id" => grafana_auth_google_client_id,
  "grafana_auth_google_client_secret" => grafana_auth_google_client_secret,
  "google_paas_admin_client_id" => google_paas_admin_client_id,
  "google_paas_admin_client_secret" => google_paas_admin_client_secret,
)
