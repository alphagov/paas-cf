
RSpec.describe "syslog forwarder config" do
  let(:manifest) { manifest_with_defaults }
  let(:syslog_addon) { manifest.fetch('addons').find { |a| a['name'] == 'syslog_forwarder' } }
  let(:syslog_properties) { syslog_addon.fetch('jobs').find { |j| j['name'] == 'syslog_forwarder' }.fetch('properties') }

  it "adds the syslog_forwarder addon" do
    expect(syslog_addon).to be
  end

  it "configures the addon properties" do
    expect(syslog_properties['syslog']['address']).to eq("logsearch-ingestor.unit-test.dev.paas.example.com")
  end
end
