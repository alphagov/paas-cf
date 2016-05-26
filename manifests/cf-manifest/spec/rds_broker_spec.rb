
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
end
