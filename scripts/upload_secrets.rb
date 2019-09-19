#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'
require 'yaml'
require 'tempfile'
require 'aws-sdk'
require 'base64'

def upload_secrets(credhub_namespaces, secrets)
  credentials = secrets.flat_map do |secret, value|
    credhub_namespaces.map do |namespace|
      {
        'name' => "#{namespace}/#{secret}",
        'type' => 'value',
        'value' => value.chomp,
      }
    end
  end

  import_to_credhub('credentials' => credentials)
end

def import_to_credhub credhub_secrets
  deploy_env = ENV.fetch('DEPLOY_ENV')
  region = ENV.fetch('AWS_REGION') { ENV.fetch('AWS_DEFAULT_REGION') }
  system_dns_zone_name = ENV.fetch('SYSTEM_DNS_ZONE_NAME')

  s3 = Aws::S3::Resource.new(region: region)

  state_bucket = s3.bucket("gds-paas-#{deploy_env}-state")
  bosh_id_rsa = Base64.encode64(state_bucket.object('id_rsa').get.body.read)
  bosh_ca_cert = state_bucket.object('bosh-CA.crt').get.body.read

  bosh_secrets = YAML.safe_load(state_bucket.object('bosh-secrets.yml').get.body)
  credhub_secret = bosh_secrets.dig('secrets', 'bosh_credhub_admin_client_password')

  bosh_vars_store = YAML.safe_load(state_bucket.object('bosh-vars-store.yml').get.body)
  bosh_client_secret = bosh_vars_store.fetch('admin_password')
  credhub_ca_cert = bosh_vars_store.dig('credhub_tls', 'ca') + bosh_vars_store.dig('uaa_ssl', 'ca')

  ec2 = Aws::EC2::Resource.new(region: region)

  bosh_ip = ec2.instances(filters: [
    { name: 'tag:deploy_env', values: [deploy_env] },
    { name: 'tag:instance_group', values: ['bosh'] },
  ]).first.public_ip_address

  env_vars = {
      'BOSH_ID_RSA' => bosh_id_rsa,
      'BOSH_IP' => bosh_ip,
      'BOSH_CLIENT' => 'admin',
      'BOSH_CLIENT_SECRET' => bosh_client_secret,
      'BOSH_ENVIRONMENT' => "bosh.#{system_dns_zone_name}",
      'BOSH_CA_CERT' => bosh_ca_cert,
      'BOSH_DEPLOYMENT' => deploy_env,
      'CREDHUB_SERVER' => "https://bosh.#{system_dns_zone_name}:8844/api",
      'CREDHUB_CLIENT' => "credhub-admin",
      'CREDHUB_SECRET' => credhub_secret,
      'CREDHUB_CA_CERT' => credhub_ca_cert,
      'CREDHUB_PROXY' => "socks5://localhost:25555",
  }
  env_vars.each { |key, value| ENV[key] = value }

  env_params = env_vars.keys.flat_map { |var| ['--env', var] }

  credhub_secrets_file = Tempfile.new('credhub-secrets', '/tmp')
  credhub_secrets_file.write(credhub_secrets.to_yaml)
  credhub_secrets_file.close

  system(
    'docker',
    'run',
    '--rm',
    *env_params,
    '-v', "#{credhub_secrets_file.path}:/root/import.yml",
    'governmentpaas/bosh-shell:cf791cec329bff5577cd8b3c9511bf89f988b5d4',
    '-c', 'credhub import -f /root/import.yml'
  )
end
