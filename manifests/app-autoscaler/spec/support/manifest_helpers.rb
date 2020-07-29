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
    env["BOSH_CA_CERT"] = "bosh-ca-cert"
    env["VCAP_PASSWORD"] = "vcap-password"
    env
  end

  def render_manifest_with_defaults
    workdir = Dir.mktmpdir("workdir")

    vars_store = Tempfile.new(["vars-store", ".yml"])
    copy_terraform_fixtures("#{workdir}/terraform-outputs", %w[cf])

    env = fake_env_vars
    env["PAAS_CF_DIR"] = root.to_s
    env["WORKDIR"] = workdir
    env["VARS_STORE"] = vars_store.path

    output, error, status = Open3.capture3(env, "#{root}/manifests/app-autoscaler/scripts/generate-manifest.sh")
    expect(status).to be_success, "generate-manifest.sh exited #{status.exitstatus}, stderr:\n#{error}"

    DeepFreeze.freeze(PropertyTree.load_yaml(output))
  ensure
    FileUtils.rm_r(workdir)
  end
end

RSpec.configuration.include ManifestHelpers
