#!/usr/bin/env ruby
# frozen_string_literal: true

def get_secrets()
  ENV['PASSWORD_STORE_DIR'] = ENV['LOGIT_PASSWORD_STORE_DIR']
  begin
    credhub_namespace = ENV['CREDHUB_NAMESPACE'].split(',')
  rescue NoMethodError # env var was not set
    credhub_namespace = ['/concourse/main/create-cloudfoundry', "/#{ENV['DEPLOY_ENV']}/#{ENV['DEPLOY_ENV']}"]
  end
  logit_syslog_address = ENV['LOGIT_SYSLOG_ADDRESS'] || `pass "logit/${MAKEFILE_ENV_TARGET}/syslog_address"`
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
