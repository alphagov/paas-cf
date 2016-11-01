require 'open3'
require 'yaml'
require 'singleton'


module ManifestHelpers
  class Cache
    include Singleton
    attr_accessor :manifest_with_defaults
    attr_accessor :terraform_fixture
  end

  def manifest_with_defaults
    Cache.instance.manifest_with_defaults ||= load_default_manifest
  end

  def terraform_fixture(key)
    Cache.instance.terraform_fixture ||= load_terraform_fixture.fetch('terraform_outputs')
    Cache.instance.terraform_fixture.fetch(key.to_s)
  end

private

  def fake_env_vars
    ENV["AWS_ACCOUNT"] = "dev"
    ENV["DATADOG_API_KEY"] = "abcd1234"
  end

  def render(arg_list)
    fake_env_vars
    output, error, status = Open3.capture3(arg_list.join(' '))
    expect(status).to be_success, "build_manifest.sh exited #{status.exitstatus}, stderr:\n#{error}"
    output
  end

  def grafana_dashboards_manifest_path
    File.expand_path("../../../grafana/grafana-dashboards-manifest.yml", __FILE__)
  end

  def render_grafana_dashboards_manifest
    output, = Open3.capture2([
      File.expand_path("../../../scripts/grafana-dashboards-manifest.rb", __FILE__),
      File.expand_path("../../../grafana", __FILE__),
    ].join(' '))
    File.write(grafana_dashboards_manifest_path, output)
  end

  def remove_grafana_dashboards_manifest
    FileUtils.rm(grafana_dashboards_manifest_path)
  end

  def load_default_manifest(environment = "default")
    render_grafana_dashboards_manifest
    manifest = render([
        File.expand_path("../../../../shared/build_manifest.sh", __FILE__),
        File.expand_path("../../../manifest/*.yml", __FILE__),
        File.expand_path("../../../manifest/data/*.yml", __FILE__),
        grafana_dashboards_manifest_path,
        File.expand_path("../../../manifest/env-specific/cf-#{environment}.yml", __FILE__),
        File.expand_path("../../../../shared/deployments/datadog-agent.yml", __FILE__),
        File.expand_path("../../../stubs/datadog-nozzle.yml", __FILE__),
        File.expand_path("../../../../shared/spec/fixtures/terraform/*.yml", __FILE__),
        File.expand_path("../../../../shared/spec/fixtures/cf-secrets.yml", __FILE__),
        File.expand_path("../../../../shared/spec/fixtures/cf-ssl-certificates.yml", __FILE__),
    ])

    cloud_config = render([
        File.expand_path("../../../../shared/build_manifest.sh", __FILE__),
        File.expand_path("../../../cloud-config/*.yml", __FILE__),
        File.expand_path("../../../../shared/spec/fixtures/terraform/*.yml", __FILE__),
        File.expand_path("../../../../shared/spec/fixtures/cf-secrets.yml", __FILE__),
        File.expand_path("../../../../shared/spec/fixtures/cf-ssl-certificates.yml", __FILE__),
    ])

    # Deep freeze the object so that it's safe to use across multiple examples
    # without risk of state leaking.
    deep_freeze(YAML.load(manifest + cloud_config))

  ensure
    remove_grafana_dashboards_manifest
  end

  def load_runtime_config
    runtime_config = render([
      File.expand_path("../../../../shared/build_manifest.sh", __FILE__),
      File.expand_path("../../../runtime-config/runtime-config-base.yml", __FILE__),
      File.expand_path("../../../runtime-config/datadog-agent-addon.yml", __FILE__),
      File.expand_path("../../../../shared/deployments/datadog-agent.yml", __FILE__),
      File.expand_path("../../../../shared/deployments/collectd.yml", __FILE__),
      File.expand_path("../../../../shared/spec/fixtures/terraform/*.yml", __FILE__),
      File.expand_path("../../../../shared/spec/fixtures/cf-secrets.yml", __FILE__),
    ])

    # Deep freeze the object so that it's safe to use across multiple examples
    # without risk of state leaking.
    deep_freeze(YAML.load(runtime_config))
  end

  def load_terraform_fixture
    data = YAML.load_file(File.expand_path("../../../../shared/spec/fixtures/terraform/terraform-outputs.yml", __FILE__))
    deep_freeze(data)
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
