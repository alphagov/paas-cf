#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'upload_secrets.rb'

ENV['PASSWORD_STORE_DIR'] = ENV['AIVEN_PASSWORD_STORE_HIGH_DIR'] || ENV['LOGIT_PASSWORD_STORE_DIR']

deploy_env = ENV.fetch('DEPLOY_ENV')

credhub_namespaces = [
  '/concourse/main/create-cloudfoundry',
  "/#{deploy_env}/#{deploy_env}",
]

google_oauth_client_id = ENV['GOOGLE_OAUTH_CLIENT_ID'] || `pass "google/${MAKEFILE_ENV_TARGET}/oauth/client_id"`
google_oauth_client_secret = ENV['GOOGLE_OAUTH_CLIENT_SECRET'] || `pass "google/${MAKEFILE_ENV_TARGET}/oauth/client_secret"`
grafana_auth_google_client_id = ENV['GRAFANA_AUTH_GOOGLE_CLIENT_ID'] || `pass "google/${MAKEFILE_ENV_TARGET}/oauth/grafana_client_id"`
grafana_auth_google_client_secret = ENV['GRAFANA_AUTH_GOOGLE_CLIENT_SECRET'] || `pass "google/${MAKEFILE_ENV_TARGET}/oauth/grafana_client_secret"`
google_paas_admin_client_id = ENV['GOOGLE_PAAS_ADMIN_CLIENT_ID'] || `pass "google/${MAKEFILE_ENV_TARGET}/oauth/paas_admin_client_id"`
google_paas_admin_client_secret = ENV['GOOGLE_PAAS_ADMIN_CLIENT_SECRET'] || `pass "google/${MAKEFILE_ENV_TARGET}/oauth/paas_admin_client_secret"`

upload_secrets(
  credhub_namespaces,
  'google_oauth_client_id' => google_oauth_client_id,
  'google_oauth_client_secret' => google_oauth_client_secret,
  'grafana_auth_google_client_id' => grafana_auth_google_client_id,
  'grafana_auth_google_client_secret' => grafana_auth_google_client_secret,
  'google_paas_admin_client_id' => google_paas_admin_client_id,
  'google_paas_admin_client_secret' => google_paas_admin_client_secret,
)
