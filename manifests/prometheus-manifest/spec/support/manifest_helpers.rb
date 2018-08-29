require 'singleton'
require 'open3'

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

    DeepFreeze.freeze(PropertyTree.load_yaml(output))
  end
end

RSpec.configuration.include ManifestHelpers
