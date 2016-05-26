
RSpec.describe "RDS broker properties" do
  let(:manifest) { manifest_with_defaults }
  let(:properties) { manifest.fetch("properties") }

  describe "adding RDS access to application security groups" do

    it "appends a security group definition" do
      defs = properties.fetch("cc").fetch("security_group_definitions")
      expect(defs.length).to be > 1 # Ensure the default ones haven't been replaced

      rds_sg = defs.find {|d| d["name"] == "rds_broker_instances" }
      expect(rds_sg).to be
      expect(rds_sg["rules"]).to eq([{
        "protocol" => "tcp",
        "destination" => terraform_fixture("aws_backing_service_cidr_all"),
        "ports" => "5432",
      }])
    end

    it "adds to default_running_security_groups" do
      sgs = properties.fetch("cc").fetch("default_running_security_groups")
      expect(sgs.length).to be > 1 # Ensure the default ones haven't been replaced
      expect(sgs.last).to eq("rds_broker_instances")
    end

    it "adds to default_staging_security_groups" do
      sgs = properties.fetch("cc").fetch("default_staging_security_groups")
      expect(sgs.length).to be > 1 # Ensure the default ones haven't been replaced
      expect(sgs.last).to eq("rds_broker_instances")
    end
  end

  describe "service plans" do
    let(:rds_broker_job) {
      manifest.fetch("jobs").find {|j| j["name"] == "rds_broker_z1" }
    }
    let(:services) {
      rds_broker_job.fetch("properties").fetch("rds-broker").fetch("catalog").fetch("services")
    }
    let(:all_plans) {
      services.map {|s| s["plans"]}.flatten(1)
    }

    specify "all services have a unique id" do
      all_ids = services.map {|s| s["id"] }
      duplicated_ids = all_ids.select {|id| all_ids.count(id) > 1}.uniq
      expect(duplicated_ids).to be_empty,
        "found duplicate service ids (#{duplicated_ids.join(',')})"
    end

    specify "all services have a unique name" do
      all_names = services.map {|s| s["name"] }
      duplicated_names = all_names.select {|name| all_names.count(name) > 1}.uniq
      expect(duplicated_names).to be_empty,
        "found duplicate service names (#{duplicated_names.join(',')})"
    end

    specify "all plans have a unique id" do
      all_ids = all_plans.map {|p| p["id"] }
      duplicated_ids = all_ids.select {|id| all_ids.count(id) > 1}.uniq
      expect(duplicated_ids).to be_empty,
        "found duplicate plan ids (#{duplicated_ids.join(',')})"
    end

    specify "all plans have a unique name" do
      all_names = all_plans.map {|p| p["name"] }
      duplicated_names = all_names.select {|name| all_names.count(name) > 1}.uniq
      expect(duplicated_names).to be_empty,
        "found duplicate plan names (#{duplicated_names.join(',')})"
    end
  end
end
