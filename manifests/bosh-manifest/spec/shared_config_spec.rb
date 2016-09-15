RSpec.describe "Gets properties from shared config" do
  let(:manifest) { manifest_with_defaults }
  let(:bosh_properties) { manifest.fetch("jobs").select { |x| x["name"] == "bosh" }.first["properties"] }

  it "for collectd" do
    expect(bosh_properties["collectd"]["interval"]).to eq 10
  end

  it "for datadog" do
    expect(bosh_properties["use_dogstatsd"]).to eq false
  end
end
