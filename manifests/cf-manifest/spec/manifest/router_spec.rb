RSpec.describe "router properties" do
  let(:manifest) { manifest_with_defaults }
  let(:properties) { manifest.fetch("properties") }

  it "does not streams the access_logs to syslog" do
    enable_access_log_streaming = properties.fetch("router").fetch("enable_access_log_streaming")
    expect(enable_access_log_streaming).to be false
  end
end
