
RSpec.describe "Logsearch properties" do
  let(:manifest) { manifest_with_defaults }
  let(:instance_groups) { manifest.fetch("instance_groups") }

  describe "curator instance group" do
    let(:properties) { manifest.fetch("instance_groups.maintenance.jobs.curator.properties") }
    it "contains purge_logs.retention_period. We expect retention period to be 30 days." do
      defs = properties.fetch("curator").fetch("purge_logs")
      expect(defs.fetch("retention_period")).to eq(30)
    end
  end

  describe "parsers" do
    let(:queue_ips) {
      manifest.fetch("instance_groups.queue.networks").first.fetch("static_ips")
    }

    it "points the parsers at the correct queues" do
      expect(manifest.fetch("instance_groups.parser.jobs.parser.properties.logstash_parser.inputs.0.options.host")).to eq(queue_ips[0])
      expect(manifest.fetch("instance_groups.parser.jobs.parser.properties.logstash_parser.inputs.1.options.host")).to eq(queue_ips[1])
    end
  end
end
