#!/usr/bin/env ruby
# frozen_string_literal: true

def get_secrets()
  ENV['PASSWORD_STORE_DIR'] = ENV['PAGERDUTY_PASSWORD_STORE_DIR']
  credhub_namespace = ENV['CREDHUB_NAMESPACE'] || '/concourse/main/create-cloudfoundry'

  alertmanager_pagerduty_service_key = ENV['ALERTMANAGER_PAGERDUTY_SERVICE_KEY'] || `pass "pagerduty/${MAKEFILE_ENV_TARGET}/alertmanager_pagerduty_service_key"`

  {
    'config' => {
      'credhub_namespace' => credhub_namespace,
      's3_path' => "s3://gds-paas-#{ENV['DEPLOY_ENV']}-state/pagerduty-secrets.yml"
    },
    'secrets' => {
      'alertmanager_pagerduty_service_key' => alertmanager_pagerduty_service_key
    }
  }
end
