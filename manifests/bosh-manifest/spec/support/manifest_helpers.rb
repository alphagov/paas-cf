require 'singleton'
require 'open3'
require 'yaml'

module ManifestHelpers
  class Cache
    include Singleton
    attr_accessor :manifest_with_defaults
  end

  def manifest_with_defaults
    Cache.instance.manifest_with_defaults ||= load_default_manifest
  end

private

  def load_default_manifest
    ENV["AWS_ACCOUNT"] = "dev"
    ENV["DATADOG_API_KEY"] = "abcd1234"

    output, error, status = Open3.capture3(
      [
        File.expand_path("../../../../shared/build_manifest.sh", __FILE__),
        File.expand_path("../../../deployments/*.yml", __FILE__),
        File.expand_path("../../../deployments/aws/*.yml", __FILE__),
        File.expand_path("../../fixtures/bosh-secrets.yml", __FILE__),
        File.expand_path("../../fixtures/bosh-ssl-certificates.yml", __FILE__),
        File.expand_path("../../fixtures/bosh-terraform-outputs.yml", __FILE__),
        File.expand_path("../../../../shared/deployments/datadog-agent.yml", __FILE__),
        File.expand_path("../../../../shared/deployments/collectd.yml", __FILE__),
        File.expand_path("../../../extensions/datadog-agent.yml", __FILE__),
      ].join(' ')
    )
    expect(status).to be_success, "build_manifest.sh exited #{status.exitstatus}, stderr:\n#{error}"

    # Deep freeze the object so that it's safe to use across multiple examples
    # without risk of state leaking.
    deep_freeze(YAML.load(output))
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
