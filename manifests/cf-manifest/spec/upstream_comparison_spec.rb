require 'open3'

RSpec.describe "comparing with upstream" do
  let(:upstream_manifest) {
    #output, error, status = Open3.capture3(File.expand_path("../../upstream/build_manifest.sh", __FILE__))
    #expect(status).to be_success, "build_manifest.sh exited #{status.exitstatus}, stderr:\n#{error}"
    YAML.load_file(File.expand_path("../../upstream-cf-manifest.yml", __FILE__))
  }

  specify "the output matches upstream" do
    expect(
      manifest_with_defaults.reject {|k,v| %w(meta lamb_meta).include?(k) }.to_yaml
    ).to eq(
      upstream_manifest.reject {|k,v| k == "meta" }.to_yaml
    )
  end
end
