require 'open3'

RSpec.describe "comparing with reference" do
  let(:reference_manifest) {
    YAML.load_file(File.expand_path("../../reference-bosh-manifest.yml", __FILE__))
  }

  specify "the output matches reference manifest" do
    expect(
      manifest_with_defaults.reject {|k,v| %w(meta lamb_meta).include?(k) }.to_yaml
    ).to eq(
      reference_manifest.reject {|k,v| k == "meta" }.to_yaml
    )
  end
end
