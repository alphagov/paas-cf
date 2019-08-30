#!/usr/bin/env ruby
# frozen_string_literal: true

def get_secrets()
  ENV['PASSWORD_STORE_DIR'] = ENV['LOGIT_PASSWORD_STORE_DIR']
  credhub_namespace = ENV['CREDHUB_NAMESPACE'] || '/concourse/main/create-cloudfoundry'
  logit_syslog_address = ENV['CREDHUB_NAMESPACE'] || `pass "logit/${MAKEFILE_ENV_TARGET}/syslog_address"`
  logit_syslog_port = ENV['LOGIT_SYSLOG_PORT'] || `pass "logit/${MAKEFILE_ENV_TARGET}/syslog_port"`
  logit_ca_cert = ENV['LOGIT_CA_CERT'] || `pass "logit/${MAKEFILE_ENV_TARGET}/ca_cert"`

  {
    'config' => {
      'credhub_namespace' => credhub_namespace,
      's3_path' => "s3://gds-paas-#{ENV['DEPLOY_ENV']}-state/logit-secrets.yml"
    },
    'secrets' => {
      'logit_syslog_address' => logit_syslog_address,
      'logit_syslog_port' => logit_syslog_port,
      'logit_ca_cert' => logit_ca_cert
    }
  }
end
