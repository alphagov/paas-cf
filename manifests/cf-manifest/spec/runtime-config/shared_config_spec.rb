
RSpec.describe "Runtime config" do
  let(:runtime_config) { load_runtime_config }

  it "uses a shared collectd config file" do
    collectd_addon = runtime_config.fetch("addons").find { |addon| addon["name"] == "collectd" }
    expect(collectd_addon.fetch("properties").fetch("collectd").fetch("interval")).to eq 10
  end

  it "has datadog included with properties from shared config" do
    datadog_addon = runtime_config.fetch("addons").find { |addon| addon["name"] == "datadog-agent" }
    expect(datadog_addon.fetch("properties").fetch("use_dogstatsd")).to eq false
  end
end
