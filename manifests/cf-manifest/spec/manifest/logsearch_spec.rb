
RSpec.describe "Logsearch properties" do
  let(:manifest) { manifest_with_defaults }
  let(:properties) { manifest.fetch("properties") }
  let(:instance_groups) { manifest.fetch("instance_groups") }

  def get_instance_group(instance_group_name)
    instance_group = instance_groups.select { |i| i["name"] == instance_group_name }.first
    if instance_group == nil
      raise "No instance_group named '#{instance_group_name}' known. Known instance_groups are #{instance_groups.collect { |ig_hash| ig_hash['name'] }}"
    else
      instance_group
    end
  end

  describe "curator instance group" do
    it "contains purge_logs.retention_period. We expect retention period to be 30 days." do
      defs = properties.fetch("curator").fetch("purge_logs")
      expect(defs.fetch("retention_period")).to eq(30)
    end
  end

  describe "parsers" do
    let(:queue_ips) { get_instance_group("queue").fetch("networks").first.fetch("static_ips") }

    it "points the parsers at the correct queues" do
      expect(get_instance_group("parser_z1")["properties"]["redis"]["host"]).to eq(queue_ips[0])
      expect(get_instance_group("parser_z2")["properties"]["redis"]["host"]).to eq(queue_ips[1])
    end
  end
end
