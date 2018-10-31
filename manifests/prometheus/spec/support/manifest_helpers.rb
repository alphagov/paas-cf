require 'singleton'
require 'open3'
require 'tempfile'

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
    vars_store = Tempfile.new(['vars-store', '.yml'])

    env = {
      'PAAS_CF_DIR' => root.to_s,
      'VARS_STORE' => vars_store.path,
      'VARS_FILE' => "#{root}/manifests/prometheus/spec/fixtures/prometheus-vars-file.yml",
    }
    output, error, status = Open3.capture3(env, "#{root}/manifests/prometheus/scripts/generate-manifest.sh")
    expect(status).to be_success, "generate-manifest.sh exited #{status.exitstatus}, stderr:\n#{error}"

    DeepFreeze.freeze(PropertyTree.load_yaml(output))
  end
end

RSpec.configuration.include ManifestHelpers
