
RSpec.describe "Logsearch properties" do
  let(:manifest) { manifest_with_defaults }
  let(:properties) { manifest.fetch("properties") }

  describe "curator instance group" do
    it "contains purge_logs.retention_period. We expect retention period to be 30 days." do
      defs = properties.fetch("curator").fetch("purge_logs")
      expect(defs.fetch("retention_period")).to eq(30)
    end
  end
end
