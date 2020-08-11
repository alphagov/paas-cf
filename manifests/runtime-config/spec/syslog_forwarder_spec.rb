RSpec.describe "syslog forwarder" do
  let(:config) { runtime_config_with_defaults }
  let(:syslog_addon) { config.fetch("addons").find { |a| a["name"] == "syslog_forwarder" } }
  let(:syslog_properties) { syslog_addon.fetch("jobs").find { |j| j["name"] == "syslog_forwarder" }.fetch("properties") }

  it "adds the syslog_forwarder addon" do
    expect(syslog_addon).not_to be_nil
  end

  it "configures tls to be enabled" do
    expect(syslog_properties.fetch("syslog").fetch("tls_enabled")).to be true
  end

  it "configures the addon properties" do
    expect(syslog_properties["syslog"]["address"]).to eq("((logit_syslog_address))")
    expect(syslog_properties["syslog"]["port"]).to eq "((logit_syslog_port))"
    expect(syslog_properties["syslog"]["permitted_peer"]).to eq "*.logit.io"
    expect(syslog_properties["syslog"]["ca_cert"]).to eq("((logit_ca_cert))")
  end

  it "excludes the concourse deployment" do
    expect(syslog_addon.dig("exclude", "deployments")).to include("concourse")
  end
end
