
RSpec.describe "syslog forwarder config" do
  let(:manifest) { manifest_with_defaults }
  let(:syslog_addon) { manifest.fetch('addons').find { |a| a['name'] == 'syslog_forwarder' } }
  let(:syslog_properties) { syslog_addon.fetch('jobs').find { |j| j['name'] == 'syslog_forwarder' }.fetch('properties') }

  it "adds the syslog_forwarder addon" do
    expect(syslog_addon).to be
  end

  it "configures tls to be enabled" do
    expect(syslog_properties.fetch("syslog").fetch("tls_enabled")).to be true
  end

  it "configures the addon properties" do
    expect(syslog_properties['syslog']['address']).to eq("((logit_syslog_address))")
    expect(syslog_properties['syslog']['port']).to eq "((logit_syslog_port))"
    expect(syslog_properties['syslog']['permitted_peer']).to eq "*.logit.io"
    expect(syslog_properties['syslog']['ca_cert']).to eq("((logit_ca_cert))")
  end
end
