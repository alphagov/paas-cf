RSpec.describe "Grafana" do
  let(:properties) { manifest.fetch("instance_groups.graphite.jobs.grafana.properties") }

  describe "dashboard" do
    let(:manifest) { manifest_with_defaults }
    it "contains dashboard definitions" do
      expect(properties['grafana']['dashboards']).to_not be_empty
    end
  end
end
