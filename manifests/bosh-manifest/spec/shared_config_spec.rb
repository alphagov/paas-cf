
RSpec.describe "Bosh collectd properties" do
  let(:manifest) { manifest_with_defaults }

  it "pulls from a shared config file" do
    expect(manifest.fetch("properties").fetch("collectd").fetch("interval")).to eq 10
  end
end
