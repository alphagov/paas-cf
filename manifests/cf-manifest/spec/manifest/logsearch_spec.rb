
RSpec.describe "Logsearch properties" do
  let(:manifest) { manifest_with_defaults }
  let(:properties) { manifest.fetch("properties") }

  describe "curator job" do
    it "contains purge_logs.retention_period. Retention period should not be changed without updating Privacy Policy." do
      defs = properties.fetch("curator").fetch("purge_logs")
      expect(defs.fetch("retention_period")).to eq(30)
    end
  end
end
