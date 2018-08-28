require 'singleton'
require 'open3'
require 'yaml'

module ManifestHelpers
  class Cache
    include Singleton
    attr_accessor :manifest_with_defaults
  end

  def manifest_with_defaults
    Cache.instance.manifest_with_defaults ||=
      render_manifest_with_defaults
  end

private

  def render_manifest_with_defaults
    root = Pathname.new(File.expand_path("../../../..", __dir__))

    env = {
      'PAAS_CF_DIR' => root.to_s,
    }
    output, error, status = Open3.capture3(env, "#{root}/manifests/prometheus-manifest/scripts/generate-manifest.sh")
    expect(status).to be_success, "generate-manifest.sh exited #{status.exitstatus}, stderr:\n#{error}"

    deep_freeze(YAML.safe_load(output))
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
