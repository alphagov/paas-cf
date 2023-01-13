RSpec.describe "router" do
  describe "gorouter" do
    let(:manifest) { manifest_with_defaults }
    let(:gorouter_props) { manifest.fetch("instance_groups.router.jobs.gorouter.properties.router") }

    it "has max_idle_connections set to disable keepalives" do
      expect(gorouter_props["max_idle_connections"]).to eq(0)
    end
  end
end
