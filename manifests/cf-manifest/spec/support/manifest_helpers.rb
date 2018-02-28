require 'open3'
require 'yaml'
require 'singleton'
require 'tempfile'


module ManifestHelpers
  class Cache
    include Singleton
    attr_accessor :manifest_with_defaults
    attr_accessor :cloud_config_with_defaults
    attr_accessor :terraform_fixture
    attr_accessor :cf_secrets_file
    attr_accessor :grafana_dashboards_manifest
  end

  def manifest_with_defaults
    Cache.instance.manifest_with_defaults ||= render_manifest
  end

  def manifest_with_custom_vars_file(vars_file_content)
    Tempfile.open(['custom-vars-file', '.yml']) do |file|
      file.write(vars_file_content)
      file.flush
      render_manifest("default", [file.path])
    end
  end

  def cloud_config_with_defaults
    Cache.instance.cloud_config_with_defaults ||= render_cloud_config
  end

  def terraform_fixture(key)
    Cache.instance.terraform_fixture ||= load_terraform_fixture
    Cache.instance.terraform_fixture.fetch('terraform_outputs_' + key.to_s)
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

  def render(arg_list)
    output, error, status = Open3.capture3(arg_list.map { |p| root.join(p) }.join(' '))
    expect(status).to be_success, "#{arg_list[0]} exited #{status.exitstatus}, stderr:\n#{error}"
    output
  end

  def root
    Pathname(File.expand_path("../../../..", __dir__))
  end

  def render_grafana_dashboards_manifest
    file = Tempfile.new(['test-grafana-dashboards', '.yml'])
    output, error, status =
      Open3.capture3(root.join("manifests/cf-manifest/scripts/grafana-dashboards-manifest.rb").to_s,
                     root.join("manifests/cf-manifest/grafana").to_s)
    unless status.success?
      raise "Error generating grafana dashboards, exit: #{status.exitstatus}, output:\n#{output}\n#{error}"
    end
    file.write(output)
    file.flush
    file.rewind
    file
  end

  def render_manifest(environment = "default", extra_vars_files = [])
    spruced_manifest = render(%W(
      manifests/shared/spruce_merge.sh
      manifests/cf-manifest/manifest/*.yml
      manifests/cf-manifest/stubs/datadog-nozzle.yml
      #{grafana_dashboards_manifest}
    ))

    manifest = nil
    Tempfile.open(['spruced_manifest_file', '.yml']) { |spruced_manifest_tempfile|
      spruced_manifest_tempfile << spruced_manifest
      spruced_manifest_tempfile.close

      manifest = render(%W(
        manifests/shared/bosh_interpolate.sh
        #{spruced_manifest_tempfile.path}
        manifests/cf-manifest/manifest/data/*.yml
        manifests/shared/spec/fixtures/terraform/*.yml
        manifests/shared/spec/fixtures/environment-variables.yml
        manifests/shared/spec/fixtures/cf-ssl-certificates.yml
        manifests/variables.yml
        manifests/cf-manifest/static-ips-and-ports.yml
        manifests/cf-manifest/env-specific/cf-#{environment}.yml
        #{cf_secrets_file}
      ) + extra_vars_files)
    }

    # Deep freeze the object so that it's safe to use across multiple examples
    # without risk of state leaking.
    deep_freeze(YAML.safe_load(manifest))
  end

  def render_cloud_config(environment = "default")
    spruced_manifest = render(%W(
      manifests/shared/spruce_merge.sh
      manifests/cf-manifest/cloud-config/*.yml
    ))
    manifest = nil
    Tempfile.open(['spruced_manifest_file', '.yml']) { |spruced_manifest_tempfile|
      spruced_manifest_tempfile << spruced_manifest
      spruced_manifest_tempfile.close

      manifest = render(%W(
        manifests/shared/bosh_interpolate.sh
        #{spruced_manifest_tempfile.path}
        manifests/shared/spec/fixtures/terraform/*.yml
        manifests/shared/spec/fixtures/environment-variables.yml
        manifests/shared/spec/fixtures/cf-ssl-certificates.yml
        manifests/variables.yml
        manifests/cf-manifest/env-specific/cf-#{environment}.yml
        #{cf_secrets_file}
      ))
    }
    deep_freeze(YAML.safe_load(manifest))
  end

  def load_terraform_fixture
    data = YAML.load_file(root.join("manifests/shared/spec/fixtures/terraform/terraform-outputs.yml"))
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
