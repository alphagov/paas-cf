#!/usr/bin/env ruby
# frozen_string_literal: true

require 'aws-sdk'
require 'yaml'

#
# # $NAME_OF_SECRET_AREA "$URL_OF_OLD_SECRET_FILE_IN_S3"
# # $JQ_PATH_TO_SECRET VS $CREDHUB_PATH_TO_SECRET
#
# AIVEN "s3://gds-paas-${DEPLOY_ENV}-state/aiven-secrets.yml"
# aiven_api_token VS /prod/prod/aiven_api_token
#
# GOOGLE OAUTH "s3://gds-paas-${DEPLOY_ENV}-state/google-oauth-secrets.yml"
# secrets.google_oauth_client_id VS /prod/prod/google_oauth_client_id
# secrets.google_oauth_client_secret VS /prod/prod/google_oauth_client_secret
# secrets.grafana_auth_google_client_id VS /prod/prod/grafana_auth_google_client_id
# secrets.grafana_auth_google_client_secret VS /prod/prod/grafana_auth_google_client_secret
# secrets.google_paas_admin_client_id VS /prod/prod/google_paas_admin_client_id
# secrets.google_paas_admin_client_secret VS /prod/prod/google_paas_admin_client_secret
#
# LOGIT "s3://gds-paas-${DEPLOY_ENV}-state/logit-secrets.yml"
# meta.logit.syslog_address VS /prod/prod/logit_syslog_address
# meta.logit.syslog_port VS /prod/prod/logit_syslog_port
# meta.logit.elasticsearch_url VS /prod/prod/logit_elasticsearch_url
# meta.logit.elasticsearch_api_key VS /prod/prod/logit_elasticsearch_api_key
# meta.logit.ca_cert VS /prod/prod/logit_ca_cert
#
# MICROSOFT OAUTH "s3://gds-paas-${DEPLOY_ENV}-state/microsoft-oauth-secrets.yml"
# secrets.microsoft_oauth_tenant_id VS /prod/prod/microsoft_oauth_tenant_id
# secrets.microsoft_oauth_client_id VS /prod/prod/microsoft_oauth_client_id
# secrets.microsoft_oauth_client_secret VS /prod/prod/microsoft_oauth_client_secret
# secrets.microsoft_adminoidc_tenant_id VS /prod/prod/microsoft_adminoidc_tenant_id
# secrets.microsoft_adminoidc_client_id VS /prod/prod/microsoft_adminoidc_client_id
# secrets.microsoft_adminoidc_client_secret VS /prod/prod/microsoft_adminoidc_client_secret
#
# NOTIFY "s3://gds-paas-${DEPLOY_ENV}-state/notify-secrets.yml"
# secrets.notify_api_key VS /prod/prod/notify_api_key
#
# PAGERDUTY "s3://gds-paas-${DEPLOY_ENV}-state/pagerduty-secrets.yml"
# alertmanager_pagerduty_24_7_service_key VS /prod/prometheus/alertmanager_pagerduty_24_7_service_key
# alertmanager_pagerduty_in_hours_service_key VS /prod/prometheus/alertmanager_pagerduty_in_hours_service_key

crosscheck_config = {
  "AIVEN" => {
    "s3_url" => "s3://gds-paas-#{ENV['DEPLOY_ENV']}-state/aiven-secrets.yml",
    "secrets" => { "aiven_api_token" => "/#{ENV['DEPLOY_ENV']}/#{ENV['DEPLOY_ENV']}/aiven_api_token" }
  },
  "GOOGLE OAUTH" => {
    "s3_url" => "s3://gds-paas-#{ENV['DEPLOY_ENV']}-state/google-oauth-secrets.yml",
    "secrets" => {
      "secrets.google_oauth_client_id" => "/#{ENV['DEPLOY_ENV']}/#{ENV['DEPLOY_ENV']}/google_oauth_client_id",
      "secrets.google_oauth_client_secret" => "/#{ENV['DEPLOY_ENV']}/#{ENV['DEPLOY_ENV']}/google_oauth_client_secret",
      "secrets.grafana_auth_google_client_id" => "/#{ENV['DEPLOY_ENV']}/#{ENV['DEPLOY_ENV']}/grafana_auth_google_client_id",
      "secrets.grafana_auth_google_client_secret" => "/#{ENV['DEPLOY_ENV']}/#{ENV['DEPLOY_ENV']}/grafana_auth_google_client_secret",
      "secrets.google_paas_admin_client_id" => "/#{ENV['DEPLOY_ENV']}/#{ENV['DEPLOY_ENV']}/google_paas_admin_client_id",
      "secrets.google_paas_admin_client_secret" => "/#{ENV['DEPLOY_ENV']}/#{ENV['DEPLOY_ENV']}/google_paas_admin_client_secret"
    }
  },
  "LOGIT" => {
    "s3_url" => "s3://gds-paas-#{ENV['DEPLOY_ENV']}-state/logit-secrets.yml",
    "secrets" => {
      "meta.logit.syslog_address" => "/#{ENV['DEPLOY_ENV']}/#{ENV['DEPLOY_ENV']}/logit_syslog_address",
      "meta.logit.syslog_port" => "/#{ENV['DEPLOY_ENV']}/#{ENV['DEPLOY_ENV']}/logit_syslog_port",
      "meta.logit.elasticsearch_url" => "/#{ENV['DEPLOY_ENV']}/#{ENV['DEPLOY_ENV']}/logit_elasticsearch_url",
      "meta.logit.elasticsearch_api_key" => "/#{ENV['DEPLOY_ENV']}/#{ENV['DEPLOY_ENV']}/logit_elasticsearch_api_key",
      "meta.logit.ca_cert" => "/#{ENV['DEPLOY_ENV']}/#{ENV['DEPLOY_ENV']}/logit_ca_cert"
    }
  },
  "MICROSOFT OAUTH" => {
    "s3_url" => "s3://gds-paas-#{ENV['DEPLOY_ENV']}-state/microsoft-oauth-secrets.yml",
    "secrets" => {
      "secrets.microsoft_oauth_tenant_id" => "/#{ENV['DEPLOY_ENV']}/#{ENV['DEPLOY_ENV']}/microsoft_oauth_tenant_id",
      "secrets.microsoft_oauth_client_id" => "/#{ENV['DEPLOY_ENV']}/#{ENV['DEPLOY_ENV']}/microsoft_oauth_client_id",
      "secrets.microsoft_oauth_client_secret" => "/#{ENV['DEPLOY_ENV']}/#{ENV['DEPLOY_ENV']}/microsoft_oauth_client_secret",
      "secrets.microsoft_adminoidc_tenant_id" => "/#{ENV['DEPLOY_ENV']}/#{ENV['DEPLOY_ENV']}/microsoft_adminoidc_tenant_id",
      "secrets.microsoft_adminoidc_client_id" => "/#{ENV['DEPLOY_ENV']}/#{ENV['DEPLOY_ENV']}/microsoft_adminoidc_client_id",
      "secrets.microsoft_adminoidc_client_secret" => "/#{ENV['DEPLOY_ENV']}/#{ENV['DEPLOY_ENV']}/microsoft_adminoidc_client_secret"
    }
  },
  "NOTIFY" => {
    "s3_url" => "s3://gds-paas-#{ENV['DEPLOY_ENV']}-state/notify-secrets.yml",
    "secrets" => {
      "secrets.notify_api_key" => "/#{ENV['DEPLOY_ENV']}/#{ENV['DEPLOY_ENV']}/notify_api_key"
    }
  },
  "PAGERDUTY" => {
    "s3_url" => "s3://gds-paas-#{ENV['DEPLOY_ENV']}-state/pagerduty-secrets.yml",
    "secrets" => {
      "alertmanager_pagerduty_24_7_service_key" => "/#{ENV['DEPLOY_ENV']}/prometheus/alertmanager_pagerduty_24_7_service_key",
      "alertmanager_pagerduty_in_hours_service_key" => "/#{ENV['DEPLOY_ENV']}/prometheus/alertmanager_pagerduty_in_hours_service_key"
    }
  }
}
#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'
require 'yaml'
require 'tempfile'
require 'aws-sdk'
require 'base64'

def get_credhub_secret secret_name
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

  credhub_secret_file = Tempfile.new('credhub-secret', '/tmp')
  system(
    'docker',
    'run',
    '--rm',
    *env_params,
    '-v', "#{credhub_secret_file.path}:/root/secret.yml",
    'governmentpaas/bosh-shell:47b25fd03f4dcaf8851ee859f5e8ec0b915cf8fc',
    '-c', "credhub curl -p '/api/v1/data?name=#{secret_name}' | ruby -rjson -e 'puts JSON.parse(STDIN.read)[\"data\"][0][\"value\"]' > /root/secret.yml"
  )
  credhub_secret_file.read.chomp
end

unmatched = []

# rubocop:disable Metrics/BlockLength
crosscheck_config.each do |service_name, service_config|
  puts "-----"
  puts service_name
  puts service_config["s3_url"]
  puts "-----"

  # Download service_config["s3_url"]
  s3_dict = YAML.safe_load(`aws s3 cp #{service_config["s3_url"]} -`)

  service_config["secrets"].each do |s3_jq_path, credhub_path|
    STDOUT.write "#{s3_jq_path} VS #{credhub_path}: "

    # Get the value from the S3 file based upon the jq path
    s3_value = s3_dict
    s3_jq_segments = s3_jq_path.split(".")
    s3_jq_segments.each do |s3_jq_segment|
      s3_value = s3_value[s3_jq_segment]
    end
    s3_value = s3_value.to_s

    # Download the credhub secret
    credhub_value = get_credhub_secret credhub_path

    if s3_value == credhub_value || s3_value.chomp == credhub_value
      puts "MATCHED ✅"
    else
      puts "DID NOT MATCH ❌"
      unmatched << {
        service_name: service_name,
        s3_jq_path: s3_jq_path,
        s3_value: s3_value,
        credhub_path: credhub_path,
        credhub_value: credhub_value,
      }
    end
  end
  puts
end
# rubocop:enable Metrics/BlockLength

if unmatched.empty?
  puts "Success: All secrets matched. ✅"
else
  puts "-----"
  puts "Error: #{unmatched.length} secrets did not match. ❌"
  puts "-----"
  unmatched.each do |unmatch|
    puts "Unmatched #{unmatch[:service_name]} secret:"
    puts "        S3 JQ path = '#{unmatch[:s3_jq_path]}'"
    puts "      Credhub path = '#{unmatch[:credhub_path]}'"
    puts "       Value in S3 = '#{unmatch[:s3_value]}'"
    puts "  Value in Credhub = '#{unmatch[:credhub_value]}'"
    puts "  These should probably have been the same."
    puts
  end
  puts "There were #{unmatched.length} unmatched secrets. See above. ❌"
end
