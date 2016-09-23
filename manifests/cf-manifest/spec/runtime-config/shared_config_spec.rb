RSpec.describe "Runtime config use shared config" do
  let(:runtime_config) { load_runtime_config }
  let(:manifest) { manifest_with_defaults }
  let(:properties) { manifest.fetch("properties") }

  it "uses a shared collectd config file" do
    collectd_addon = runtime_config.fetch("addons").find { |addon| addon["name"] == "collectd" }
    expect(collectd_addon.fetch("properties").fetch("collectd").fetch("interval")).to eq 10
  end

  it "has datadog included with properties from shared config" do
    datadog_addon = runtime_config.fetch("addons").find { |addon| addon["name"] == "datadog-agent" }
    expect(datadog_addon.fetch("properties").fetch("use_dogstatsd")).to eq false
  end

  it "the dropsonde_incoming_port is the same metron_agent and loggregator" do
    metron_agent_addon = runtime_config.fetch("addons").find { |addon| addon["name"] == "metron_agent" }
    metron_agent_dropsonde_incoming_port = metron_agent_addon.fetch("properties").fetch("metron_agent").fetch("dropsonde_incoming_port")
    loggregator_dropsonde_incoming_port = properties.fetch("loggregator").fetch("dropsonde_incoming_port")

    expect(metron_agent_dropsonde_incoming_port).to eq loggregator_dropsonde_incoming_port
  end
end
