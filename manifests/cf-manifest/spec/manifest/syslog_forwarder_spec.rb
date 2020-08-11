RSpec.describe "syslog forwarder config" do
  let(:manifest) { manifest_with_defaults }
  let(:syslog_addon) { manifest.fetch("addons").find { |a| a["name"] == "syslog_forwarder" } }

  it "does not add the syslog_forwarder addon" do
    # this is in runtime config
    expect(syslog_addon).to be_nil
  end
end
