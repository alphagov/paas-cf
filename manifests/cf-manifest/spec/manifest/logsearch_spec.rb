
RSpec.describe "Logsearch properties" do
  let(:manifest) { manifest_with_defaults }
  let(:properties) { manifest.fetch("properties") }
  let(:jobs) { manifest.fetch("jobs") }

  def get_job(job_name)
    job = jobs.select { |j| j["name"] == job_name }.first
    if job == nil
      raise "No job named '#{job_name}' known. Known jobs are #{jobs.collect { |job_hash| job_hash['name'] }}"
    else
      job
    end
  end

  describe "curator job" do
    it "contains purge_logs.retention_period. We expect retention period to be 30 days." do
      defs = properties.fetch("curator").fetch("purge_logs")
      expect(defs.fetch("retention_period")).to eq(30)
    end
  end

  describe "parsers" do
    let(:queue_ips) { get_job("queue").fetch("networks").first.fetch("static_ips") }

    it "points the parsers at the correct queues" do
      expect(get_job("parser_z1")["properties"]["redis"]["host"]).to eq(queue_ips[0])
      expect(get_job("parser_z2")["properties"]["redis"]["host"]).to eq(queue_ips[1])
    end
  end
end
