RSpec.describe "Runtime config" do
  let(:runtime_config) { load_runtime_config }

  it "the syslog_forwarder is configured as a addon" do
    syslog_forwarder_addon = runtime_config.fetch("addons").find { |addon| addon["name"] == "syslog_forwarder" }

    expect(syslog_forwarder_addon).not_to be_nil
    syslog_forwarder_job = syslog_forwarder_addon.fetch("jobs").find { |job| job["name"] == "syslog_forwarder" }
    expect(syslog_forwarder_job).not_to be_nil
  end
end
