#!/usr/bin/env ruby
# frozen_string_literal: true

def get_secrets()
  ENV['PASSWORD_STORE_DIR'] = ENV['OAUTH_PASSWORD_STORE_DIR']
  credhub_namespace = ENV['CREDHUB_NAMESPACE'] || '/concourse/main/create-cloudfoundry'

  microsoft_oauth_tenant_id = ENV['MICROSOFT_OAUTH_TENANT_ID'] || `pass "microsoft/${MAKEFILE_ENV_TARGET}/oauth/tenant_id"`
  microsoft_oauth_client_id = ENV['MICROSOFT_OAUTH_CLIENT_ID'] || `pass "microsoft/${MAKEFILE_ENV_TARGET}/oauth/client_id"`
  microsoft_oauth_client_secret = ENV['MICROSOFT_OAUTH_CLIENT_SECRET'] || `pass "microsoft/${MAKEFILE_ENV_TARGET}/oauth/client_secret"`
  microsoft_adminoidc_tenant_id = ENV['MICROSOFT_ADMINOIDC_TENANT_ID'] || `pass "microsoft/${MAKEFILE_ENV_TARGET}/paas-admin-oidc/tenant_id"`
  microsoft_adminoidc_client_id = ENV['MICROSOFT_ADMINOIDC_CLIENT_ID'] || `pass "microsoft/${MAKEFILE_ENV_TARGET}/paas-admin-oidc/client_id"`
  microsoft_adminoidc_client_secret = ENV['MICROSOFT_ADMINOIDC_CLIENT_SECRET'] || `pass "microsoft/${MAKEFILE_ENV_TARGET}/paas-admin-oidc/client_secret"`

  {
    'config' => {
      'credhub_namespace' => credhub_namespace,
      's3_path' => "s3://gds-paas-#{ENV['DEPLOY_ENV']}-state/microsoft-oauth-secrets.yml"
    },
    'secrets' => {
      'microsoft_oauth_tenant_id' => microsoft_oauth_tenant_id,
      'microsoft_oauth_client_id' => microsoft_oauth_client_id,
      'microsoft_oauth_client_secret' => microsoft_oauth_client_secret,
      'microsoft_adminoidc_tenant_id' => microsoft_adminoidc_tenant_id,
      'microsoft_adminoidc_client_id' => microsoft_adminoidc_client_id,
      'microsoft_adminoidc_client_secret' => microsoft_adminoidc_client_secret
    }
  }
end
