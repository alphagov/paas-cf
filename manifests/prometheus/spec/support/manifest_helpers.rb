require "singleton"
require "open3"
require "tempfile"

module ManifestHelpers
  class Cache < ::Hash
    include Singleton
  end

  def manifest_with_defaults
    Cache.instance[:manifest_with_defaults] ||=
      render_manifest_with_defaults
  end

private

  def root
    Pathname.new(File.expand_path("../../../..", __dir__))
  end

  def fake_env_vars
    env = {}
    env["AWS_ACCOUNT"] = "dev"
    env["SYSTEM_DNS_ZONE_NAME"] = "system.example.com"
    env["APPS_DNS_ZONE_NAME"] = "apps.example.com"
    env["DEPLOY_ENV"] = "test"
    env["BOSH_URL"] = "https://bosh.example.com:25555"
    env["ENV_SPECIFIC_BOSH_VARS_FILE"] = "default.yml"
    env["GRAFANA_AUTH_GOOGLE_CLIENT_ID"] = "google-client-id"
    env["GRAFANA_AUTH_GOOGLE_CLIENT_SECRET"] = "google-client-secret"
    env["UAA_CLIENTS_CF_EXPORTER_SECRET"] = "uaa_clients_cf_exporter_secret"
    env["UAA_CLIENTS_FIREHOSE_EXPORTER_SECRET"] = "uaa_clients_firehose_exporter_secret"
    env["BOSH_CA_CERT"] = "bosh-ca-cert"
    env["BOSH_EXPORTER_PASSWORD"] = "bosh-exporter-password"
    env["VCAP_PASSWORD"] = "vcap-password"
    env
  end

  def render_manifest_with_defaults
    workdir = Dir.mktmpdir("workdir")

    vars_store = Tempfile.new(["vars-store", ".yml"])
    copy_terraform_fixtures("#{workdir}/terraform-outputs", %w(cf))
    copy_fixture_file("bosh-vars-store.yml", "#{workdir}/bosh-vars-store")
    copy_fixture_file("cf-vars-store.yml", "#{workdir}/cf-vars-store")
    copy_fixture_file("bosh-CA.crt", "#{workdir}/bosh-CA-crt")
    copy_fixture_file("bosh-secrets.yml", "#{workdir}/bosh-secrets")
    copy_fixture_file("pagerduty-secrets.yml", "#{workdir}/pagerduty-secrets")

    env = fake_env_vars
    env["PAAS_CF_DIR"] = root.to_s
    env["WORKDIR"] = workdir
    env["VARS_STORE"] = vars_store.path

    output, error, status = Open3.capture3(env, "#{root}/manifests/prometheus/scripts/generate-manifest.sh")
    expect(status).to be_success, "generate-manifest.sh exited #{status.exitstatus}, stderr:\n#{error}"

    DeepFreeze.freeze(PropertyTree.load_yaml(output))
  ensure
    FileUtils.rm_r(workdir)
  end
end

RSpec.configuration.include ManifestHelpers
