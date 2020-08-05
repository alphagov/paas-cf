RSpec.describe "diego" do
  context "with the default certificates" do
    let(:manifest) { manifest_with_defaults }
    let(:properties) { manifest.fetch("instance_groups.diego-cell.jobs.rep.properties") }

    it "has containers configured" do
      expect(properties.dig("containers")).not_to be_nil
    end

    it "has containers/proxy enabled" do
      expect(properties.dig("containers", "proxy", "enabled")).to be(true)
    end
  end

  describe "api instance" do
    let(:manifest) { manifest_with_defaults }

    subject(:instance) { manifest.fetch("instance_groups.diego-api") }

    it_behaves_like "a cf rds client"
  end
end
