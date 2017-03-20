require 'open3'
require 'yaml'
require 'singleton'
require 'tempfile'


module ManifestHelpers
  class Cache
    include Singleton
    attr_accessor :manifest_with_defaults
    attr_accessor :cloud_config
    attr_accessor :terraform_fixture
    attr_accessor :cf_secrets_file
    attr_accessor :grafana_dashboards_manifest
  end

  def manifest_with_defaults
    Cache.instance.manifest_with_defaults ||= load_default_manifest
  end

  def cloud_config
    Cache.instance.cloud_config ||= render_cloud_config
  end

  def terraform_fixture(key)
    Cache.instance.terraform_fixture ||= load_terraform_fixture.fetch('terraform_outputs')
    Cache.instance.terraform_fixture.fetch(key.to_s)
  end

  def cf_secrets_file
    Cache.instance.cf_secrets_file ||= generate_cf_secrets
    Cache.instance.cf_secrets_file.path
  end

  def grafana_dashboards_manifest
    Cache.instance.grafana_dashboards_manifest ||= render_grafana_dashboards_manifest
    Cache.instance.grafana_dashboards_manifest.path
  end

private

  def fake_env_vars
    ENV["AWS_ACCOUNT"] = "dev"
    ENV["DATADOG_API_KEY"] = "abcd1234"
    ENV["ENABLE_DATADOG"] = "true"
    ENV["OAUTH_CLIENT_ID"] = "abcd1234"
    ENV["OAUTH_CLIENT_SECRET"] = "abcd1234"
  end

  def render(arg_list)
    fake_env_vars
    output, error, status = Open3.capture3(arg_list.join(' '))
    expect(status).to be_success, "build_manifest.sh exited #{status.exitstatus}, stderr:\n#{error}"
    output
  end

  def render_grafana_dashboards_manifest
    file = Tempfile.new(['test-grafana-dashboards', '.yml'])
    output, error, status = Open3.capture3(*[
      File.expand_path("../../../scripts/grafana-dashboards-manifest.rb", __FILE__),
      File.expand_path("../../../grafana", __FILE__),
    ])
    unless status.success?
      raise "Error generating grafana dashboards, exit: #{status.exitstatus}, output:\n#{output}\n#{error}"
    end
    file.write(output)
    file.flush
    file.rewind
    file
  end

  def load_default_manifest(environment = "default")
    manifest = render([
        File.expand_path("../../../../shared/build_manifest.sh", __FILE__),
        File.expand_path("../../../manifest/*.yml", __FILE__),
        File.expand_path("../../../manifest/data/*.yml", __FILE__),
        File.expand_path("../../../../shared/spec/fixtures/terraform/*.yml", __FILE__),
        cf_secrets_file,
        File.expand_path("../../../../shared/spec/fixtures/cf-ssl-certificates.yml", __FILE__),
        grafana_dashboards_manifest,
        File.expand_path("../../../manifest/env-specific/cf-#{environment}.yml", __FILE__),
        File.expand_path("../../../stubs/datadog-nozzle.yml", __FILE__),
    ])

    # Deep freeze the object so that it's safe to use across multiple examples
    # without risk of state leaking.
    deep_freeze(YAML.load(manifest))
  end

  def render_cloud_config
    manifest = render([
        File.expand_path("../../../../shared/build_manifest.sh", __FILE__),
        File.expand_path("../../../cloud-config/*.yml", __FILE__),
        File.expand_path("../../../../shared/spec/fixtures/terraform/*.yml", __FILE__),
        cf_secrets_file,
    ])
    deep_freeze(YAML.load(manifest))
  end

  def load_terraform_fixture
    data = YAML.load_file(File.expand_path("../../../../shared/spec/fixtures/terraform/terraform-outputs.yml", __FILE__))
    deep_freeze(data)
  end

  def generate_cf_secrets
    file = Tempfile.new(['test-cf-secrets', '.yml'])
    output, error, status = Open3.capture3(File.expand_path("../../../scripts/generate-cf-secrets.rb", __FILE__))
    unless status.success?
      raise "Error generating cf-secrets, exit: #{status.exitstatus}, output:\n#{output}\n#{error}"
    end
    file.write(output)
    file.flush
    file.rewind
    file
  end

  def deep_freeze(object)
    case object
    when Hash
      object.each { |_k, v| deep_freeze(v) }
    when Array
      object.each { |v| deep_freeze(v) }
    end
    object.freeze
  end
end

RSpec.configuration.include ManifestHelpers
