
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
      manifest.fetch("jobs").find {|j| j["name"] == "rds_broker" }
    }
    let(:services) {
      rds_broker_job.fetch("properties").fetch("rds-broker").fetch("catalog").fetch("services")
    }
    let(:all_plans) {
      services.map {|s| s["plans"] }.flatten(1)
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

    describe "postgres service" do
      let(:pg_service) { services.find {|s| s["name"] == "postgres" } }
      let(:pg_plans) { pg_service.fetch("plans") }

      describe "plan rds_properties" do
        shared_examples "all postgres plans" do
          it "uses postgres 9.5" do
            expect(subject["engine_version"]).to start_with("9.5.")
          end
          it "uses solid state storage" do
            expect(subject).to include("storage_type" => "gp2")
          end
          it "sets the db subnet group and security groups from terraform" do
            expect(subject).to include(
              "db_subnet_group_name" => terraform_fixture("rds_broker_dbs_subnet_group"),
              "vpc_security_group_ids" => [terraform_fixture("rds_broker_dbs_security_group_id")],
            )
          end
        end

        shared_examples "medium sized postgres plans" do
          it_behaves_like "all postgres plans"
          it { is_expected.to include("allocated_storage" => 20) }
          it { is_expected.to include("db_instance_class" => "db.m4.large") }
        end

        describe "M-dedicated-9.5" do
          let(:plan) { pg_plans.find { |p| p["name"] == "M-dedicated-9.5" } }
          subject { plan.fetch("rds_properties") }

          it_behaves_like "medium sized postgres plans"

          it { is_expected.to include("multi_az" => false) }
        end

        describe "M-HA-dedicated-9.5" do
          let(:plan) { pg_plans.find { |p| p["name"] == "M-HA-dedicated-9.5" } }
          subject { plan.fetch("rds_properties") }

          it_behaves_like "medium sized postgres plans"

          it { is_expected.to include("multi_az" => true) }
        end
      end
    end
  end
end
