RSpec.describe "Gets properties from shared config" do
  let(:manifest) { manifest_with_defaults }

  it "for collectd" do
    expect(manifest.fetch("properties").fetch("collectd").fetch("interval")).to eq 10
  end

  it "for datadog" do
    expect(manifest.fetch("properties").fetch("use_dogstatsd")).to eq false
  end
end
