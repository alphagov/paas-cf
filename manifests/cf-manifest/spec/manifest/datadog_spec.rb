RSpec.describe "Datadog" do
  describe "when Datadog is disabled" do
    let(:manifest) { manifest_with_defaults }
    it "should not have the datadog releases" do
      expect(manifest.fetch('releases.datadog-agent', 'not_found')).to eq 'not_found'
      expect(manifest.fetch('releases.datadog-firehose-nozzle', 'not_found')).to eq 'not_found'
    end

    it "should not have the datadog-agent addon" do
      expect(manifest.fetch('addons.datadog-agent', 'not_found')).to eq 'not_found'
    end

    it "should not have nozzle instance group" do
      expect(manifest.fetch('instance_groups.nozzle', 'not_found')).to eq 'not_found'
    end

    it "should not have datadog nozzle UAA client" do
      clients = manifest.fetch('instance_groups.uaa.jobs.uaa.properties.uaa.clients')
      expect(clients.keys).to_not include 'datadog-nozzle'
    end
  end

  describe "when Datadog is enabled" do
    let(:manifest) { manifest_with_datadog_enabled }
    it "should have the datadog release" do
      expect(manifest.fetch('releases.datadog-agent', 'not_found')).to_not eq 'not_found'
      expect(manifest.fetch('releases.datadog-firehose-nozzle', 'not_found')).to_not eq 'not_found'
    end

    it "should have the datadog-agent addon" do
      expect(manifest.fetch('addons.datadog-agent', 'not_found')).to_not eq 'not_found'
    end

    it "should have nozzle instance group" do
      expect(manifest.fetch('instance_groups.nozzle', 'not_found')).to_not eq 'not_found'
    end

    it "should have datadog nozzle UAA client" do
      clients = manifest.fetch('instance_groups.uaa.jobs.uaa.properties.uaa.clients')
      expect(clients.keys).to include 'datadog-nozzle'
    end

    subject(:clients) { manifest.fetch('instance_groups.uaa.jobs.uaa.properties.uaa.clients') }

    def comma_tokenize(str)
      str.split(",").map(&:strip)
    end

    describe "datadog-nozzle client" do
      subject(:client) { clients.fetch("datadog-nozzle") }
      it {
        expect(comma_tokenize(client["authorized-grant-types"])).to contain_exactly(
          "authorization_code",
          "client_credentials",
          "refresh_token",
        )
      }
      it {
        expect(comma_tokenize(client["scope"])).to contain_exactly(
          "openid",
          "oauth.approvals",
          "doppler.firehose",
        )
      }
      it {
        expect(comma_tokenize(client["authorities"])).to contain_exactly(
          "oauth.login",
          "doppler.firehose",
        )
      }
    end
  end
end
