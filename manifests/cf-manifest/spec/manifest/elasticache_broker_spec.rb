
RSpec.describe "ElastiCache broker properties" do
  let(:manifest) { manifest_with_defaults }
  let(:properties) { manifest.fetch("instance_groups.elasticache_broker.jobs.elasticache-broker.properties.elasticache-broker") }

  describe "adding ElastiCache access to application security groups" do
    it "appends a security group definition" do
      defs = manifest.fetch("instance_groups.api.jobs.cloud_controller_ng.properties.cc.security_group_definitions")
      expect(defs.length).to be > 1 # Ensure the default ones haven't been replaced

      dest_ip_range_start = terraform_fixture_value("aws_backing_service_ip_range_start")
      dest_ip_range_stop = terraform_fixture_value("aws_backing_service_ip_range_stop")
      dest_ip_range = "#{dest_ip_range_start}-#{dest_ip_range_stop}"

      elasticache_sg = defs.find { |d| d["name"] == "elasticache_broker_instances" }
      expect(elasticache_sg).not_to be_nil
      expect(elasticache_sg["rules"]).to eq([{
        "protocol" => "tcp",
        "destination" => dest_ip_range,
        "ports" => "6379",
      }])
    end

    it "adds to default_running_security_groups" do
      sgs = manifest.fetch("instance_groups.api.jobs.cloud_controller_ng.properties.cc.default_running_security_groups")
      expect(sgs.length).to be > 1 # Ensure the default ones haven't been replaced
      expect(sgs).to include("elasticache_broker_instances")
    end

    it "adds to default_staging_security_groups" do
      sgs = manifest.fetch("instance_groups.api.jobs.cloud_controller_ng.properties.cc.default_staging_security_groups")
      expect(sgs.length).to be > 1 # Ensure the default ones haven't been replaced
      expect(sgs).to include("elasticache_broker_instances")
    end
  end

  describe "service plans" do
    let(:elasticache_broker_instance_group) do
      manifest.fetch("instance_groups.elasticache_broker")
    end
    let(:services) do
      properties.fetch("catalog").fetch("services")
    end
    let(:plan_configs) do
      properties.fetch("plan_configs")
    end
    let(:all_plans) do
      services.flat_map { |s| s["plans"] }
    end

    specify "all services have a unique id" do
      all_ids = services.map { |s| s["id"] }
      duplicated_ids = all_ids.select { |id| all_ids.count(id) > 1 }.uniq
      expect(duplicated_ids).to be_empty,
        "found duplicate service ids (#{duplicated_ids.join(',')})"
    end

    specify "all services have a unique name" do
      all_names = services.map { |s| s["name"] }
      duplicated_names = all_names.select { |name| all_names.count(name) > 1 }.uniq
      expect(duplicated_names).to be_empty,
        "found duplicate service names (#{duplicated_names.join(',')})"
    end

    specify "all plans have a unique id" do
      all_ids = all_plans.map { |p| p["id"] }
      duplicated_ids = all_ids.select { |id| all_ids.count(id) > 1 }.uniq
      expect(duplicated_ids).to be_empty,
        "found duplicate plan ids (#{duplicated_ids.join(',')})"
    end

    specify "all plans within each service have a unique name" do
      services.each do |s|
        all_names = s["plans"].map { |p| p["name"] }
        duplicated_names = all_names.select { |name| all_names.count(name) > 1 }.uniq
        expect(duplicated_names).to be_empty,
          "found duplicate plan names (#{duplicated_names.join(',')})"
      end
    end

    specify "all plans have a plan config" do
      all_plans.each do |p|
        expect(plan_configs.keys).to include(p["id"]), "plan #{p['id']} doesn't have a plan config"
      end
    end

    specify "all plans have a version" do
      all_plans.each do |p|
        version = p.dig("metadata", "AdditionalMetadata", "version")
        expect(version).to be_a(String), "plan #{p['id']} doesn't have a version"
      end
    end

    specify "all plan configs belong to a plan" do
      all_plan_ids = all_plans.map { |p| p["id"] }
      plan_configs.each do |pc_id, _|
        expect(all_plan_ids).to include(pc_id), "plan config #{pc_id} doesn't belong to a plan"
      end
    end
  end

  describe "service broker is set to be shareable" do
    let(:services) do
      properties.fetch("catalog").fetch("services")
    end

    it "each service of the elasticache service broker is shareable" do
      services.each do |service|
        service_name = service["name"]
        shareable = service.dig("metadata", "shareable")

        expect(shareable).not_to be(nil), "Service '#{service_name}' has to be shareable, but the 'shareable' parameter is missing in catalog/services/metadata"
        expect(shareable).to be(true), "Service '#{service_name}' has to be shareable, but the value of the parameter is #{shareable}"
      end
    end
  end
end
