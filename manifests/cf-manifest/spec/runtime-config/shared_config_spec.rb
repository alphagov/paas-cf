
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

  it "has syslog_forwarder configured with the address from terraform output" do
    syslog_forwarder_addon = runtime_config.fetch("addons").find { |addon| addon["name"] == "syslog_forwarder" }
    syslog_forwarder_address = syslog_forwarder_addon.fetch("properties").fetch("syslog").fetch("address")

    expect(syslog_forwarder_address).to eq terraform_fixture("logsearch_ingestor_elb_dns_name")
  end
end
