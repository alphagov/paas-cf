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

microsoft_oauth_tenant_id = ENV["MICROSOFT_OAUTH_TENANT_ID"] || `pass "microsoft/${MAKEFILE_ENV_TARGET}/oauth/tenant_id"`
microsoft_oauth_client_id = ENV["MICROSOFT_OAUTH_CLIENT_ID"] || `pass "microsoft/${MAKEFILE_ENV_TARGET}/oauth/client_id"`
microsoft_oauth_client_secret = ENV["MICROSOFT_OAUTH_CLIENT_SECRET"] || `pass "microsoft/${MAKEFILE_ENV_TARGET}/oauth/client_secret"`
microsoft_adminoidc_tenant_id = ENV["MICROSOFT_ADMINOIDC_TENANT_ID"] || `pass "microsoft/${MAKEFILE_ENV_TARGET}/paas-admin-oidc/tenant_id"`
microsoft_adminoidc_client_id = ENV["MICROSOFT_ADMINOIDC_CLIENT_ID"] || `pass "microsoft/${MAKEFILE_ENV_TARGET}/paas-admin-oidc/client_id"`
microsoft_adminoidc_client_secret = ENV["MICROSOFT_ADMINOIDC_CLIENT_SECRET"] || `pass "microsoft/${MAKEFILE_ENV_TARGET}/paas-admin-oidc/client_secret"`

upload_secrets(
  credhub_namespaces,
  "microsoft_oauth_tenant_id" => microsoft_oauth_tenant_id,
  "microsoft_oauth_client_id" => microsoft_oauth_client_id,
  "microsoft_oauth_client_secret" => microsoft_oauth_client_secret,
  "microsoft_adminoidc_tenant_id" => microsoft_adminoidc_tenant_id,
  "microsoft_adminoidc_client_id" => microsoft_adminoidc_client_id,
  "microsoft_adminoidc_client_secret" => microsoft_adminoidc_client_secret,
)
