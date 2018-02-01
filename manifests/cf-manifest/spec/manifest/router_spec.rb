RSpec.describe "router properties" do
  let(:manifest) { manifest_with_defaults }
  let(:properties) { manifest.fetch("properties") }

  it "streams the access_logs to logging" do
    enable_access_log_streaming = properties.fetch("router").fetch("enable_access_log_streaming")
    expect(enable_access_log_streaming).to be true
  end
end
