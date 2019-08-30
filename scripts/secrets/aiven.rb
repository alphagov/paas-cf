#!/usr/bin/env ruby
# frozen_string_literal: true

def get_secrets()
  ENV['PASSWORD_STORE_DIR'] = ENV['AIVEN_PASSWORD_STORE_HIGH_DIR'] || ENV['LOGIT_PASSWORD_STORE_DIR']
  credhub_namespace = ENV['CREDHUB_NAMESPACE'] || '/concourse/main/create-cloudfoundry'
  aiven_api_token = ENV['AIVEN_API_TOKEN'] || `pass "aiven.io/${MAKEFILE_ENV_TARGET}/api_token"`

  {
    'config' => {
      'credhub_namespace' => credhub_namespace,
      's3_path' => "s3://gds-paas-#{ENV['DEPLOY_ENV']}-state/aiven-secrets.yml"
    },
    'secrets' => {
      'aiven_api_token' => aiven_api_token
    }
  }
end
