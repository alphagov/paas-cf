RSpec.describe "bosh dns addon" do
  let(:manifest) { manifest_with_defaults }
  let(:bosh_dns_addon) { manifest.fetch("addons").find { |a| a["name"] == "bosh-dns" } }
  let(:bosh_dns_properties) { bosh_dns_addon.fetch("jobs").find { |j| j["name"] == "bosh-dns" }.fetch("properties") }

  it "sets up bosh dns" do
    expect(bosh_dns_addon).to_not be_nil
  end

  it "enables caching" do
    expect(bosh_dns_properties.dig("cache", "enabled")).to eq(true)
  end

  it "sets the log level correctly" do
    # We do not want to log every single DNS request because that generates
    # many logs and is not particularly useful
    expect(bosh_dns_properties.dig("log_level")).to eq("WARN")
  end
end
