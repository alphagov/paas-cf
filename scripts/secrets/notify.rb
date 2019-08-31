#!/usr/bin/env ruby
# frozen_string_literal: true

def get_secrets()
  ENV['PASSWORD_STORE_DIR'] = ENV['NOTIFY_PASSWORD_STORE_DIR']
  credhub_namespace = ENV['CREDHUB_NAMESPACE'] || '/concourse/main/create-cloudfoundry'

  notify_api_key = ENV['NOTIFY_API_KEY'] || `pass "notify/${MAKEFILE_ENV_TARGET}/api_key"`

  {
    'config' => {
      'credhub_namespace' => credhub_namespace,
      's3_path' => "s3://gds-paas-#{ENV['DEPLOY_ENV']}-state/notify-secrets.yml"
    },
    'secrets' => {
      'notify_api_key' => notify_api_key
    }
  }
end
