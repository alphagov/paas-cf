RSpec.describe "bosh dns addon" do
  let(:manifest) { manifest_with_defaults }
  let(:bosh_dns_addon) { manifest.fetch("addons").find { |a| a["name"] == "bosh-dns" } }
  let(:bosh_dns_properties) { bosh_dns_addon.fetch("jobs").find { |j| j["name"] == "bosh-dns" }.fetch("properties") }

  it "sets up bosh dns" do
    expect(bosh_dns_addon).not_to be_nil
  end

  it "enables caching" do
    expect(bosh_dns_properties.dig("cache", "enabled")).to eq(true)
  end

  it "sets the log level correctly" do
    # We do not want to log every single DNS request because that generates
    # many logs and is not particularly useful
    expect(bosh_dns_properties["log_level"]).to eq("WARN")
  end

  it "uses the PKI from the cf manifest" do
    expect(bosh_dns_properties.dig("api", "client", "tls", "ca")).to eq(
      "((/test/test/dns_api_client_tls.ca))",
    )

    expect(bosh_dns_properties.dig("api", "server", "tls", "ca")).to eq(
      "((/test/test/dns_api_server_tls.ca))",
    )

    expect(bosh_dns_properties.dig("health", "client", "tls", "ca")).to eq(
      "((/test/test/dns_healthcheck_client_tls.ca))",
    )

    expect(bosh_dns_properties.dig("health", "server", "tls", "ca")).to eq(
      "((/test/test/dns_healthcheck_server_tls.ca))",
    )
  end

  describe "aliases" do
    let(:bosh_dns_aliases_addon) do
      manifest.fetch("addons").find { |a| a["name"] == "bosh-dns-aliases" }
    end

    let(:bosh_dns_aliases_properties) do
      bosh_dns_aliases_addon["jobs"]
        .find { |a| a["name"] == "bosh-dns-aliases" }
        .fetch("properties")
    end

    let(:aliases) { bosh_dns_aliases_properties["aliases"] }
    let(:targets) { aliases.flat_map { |a| a["targets"] } }

    it "sets the networks to cf" do
      targets.each do |t|
        expect(t["network"]).to eq("cf"), "#{t} should have network cf"
      end
    end
  end
end
