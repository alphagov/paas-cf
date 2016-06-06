require 'open3'
require 'yaml'

module ManifestHelpers
  def manifest_with_defaults
    @@manifest_with_defaults ||= load_default_manifest
  end


  def terraform_fixture(key)
    @@fixture ||= load_terraform_fixture.fetch('terraform_outputs')
    @@fixture.fetch(key.to_s)
  end

  private

  def render(arg_list)
    output, error, status = Open3.capture3(arg_list.join(' '))
    expect(status).to be_success, "build_manifest.sh exited #{status.exitstatus}, stderr:\n#{error}"
    output
  end

  def load_default_manifest(environment = "default")
    manifest = render([
        File.expand_path("../../../../shared/build_manifest.sh", __FILE__),
        File.expand_path("../../../manifest/*.yml", __FILE__),
        File.expand_path("../../../manifest/data/*.yml", __FILE__),
        File.expand_path("../../../../shared/spec/fixtures/terraform/*.yml", __FILE__),
        File.expand_path("../../../../shared/spec/fixtures/cf-secrets.yml", __FILE__),
        File.expand_path("../../../../shared/spec/fixtures/cf-ssl-certificates.yml", __FILE__),
        File.expand_path("../../../manifest/env-specific/cf-#{environment}.yml", __FILE__),
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
  end

  def load_terraform_fixture
    data = YAML.load_file(File.expand_path("../../../../shared/spec/fixtures/terraform/terraform-outputs.yml", __FILE__))
    deep_freeze(data)
  end

  def deep_freeze(object)
    case object
    when Hash
      object.each { |_k,v| deep_freeze(v) }
    when Array
      object.each { |v| deep_freeze(v) }
    end
    object.freeze
  end
end

RSpec.configuration.include ManifestHelpers
