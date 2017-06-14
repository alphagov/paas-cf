
RSpec.describe "RDS broker properties" do
  let(:manifest) { manifest_with_defaults }
  let(:properties) { manifest.fetch("properties") }

  describe "adding RDS access to application security groups" do
    it "appends a security group definition" do
      defs = properties.fetch("cc").fetch("security_group_definitions")
      expect(defs.length).to be > 1 # Ensure the default ones haven't been replaced

      rds_sg = defs.find { |d| d["name"] == "rds_broker_instances" }
      expect(rds_sg).to be
      expect(rds_sg["rules"]).to eq([{
        "protocol" => "tcp",
        "destination" => terraform_fixture("aws_backing_service_cidr_all"),
        "ports" => "5432",
      }, {
        "protocol" => "tcp",
        "destination" => terraform_fixture("aws_backing_service_cidr_all"),
        "ports" => "3306",
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
      manifest.fetch("jobs").find { |j| j["name"] == "rds_broker" }
    }
    let(:services) {
      rds_broker_job.fetch("properties").fetch("rds-broker").fetch("catalog").fetch("services")
    }
    let(:all_plans) {
      services.flat_map { |s| s["plans"] }
    }

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
      services.each { |s|
        all_names = s["plans"].map { |p| p["name"] }
        duplicated_names = all_names.select { |name| all_names.count(name) > 1 }.uniq
        expect(duplicated_names).to be_empty,
          "found duplicate plan names (#{duplicated_names.join(',')})"
      }
    end

    describe "postgres service" do
      let(:pg_service) { services.find { |s| s["name"] == "postgres" } }
      let(:pg_plans) { pg_service.fetch("plans") }

      it "contains only specific plans" do
        pg_plan_names = pg_plans.map { |p| p["name"] }
        expect(pg_plan_names).to contain_exactly("Free", "S-dedicated-9.5", "S-HA-dedicated-9.5", "M-dedicated-9.5", "M-HA-dedicated-9.5", "M-HA-enc-dedicated-9.5", "L-dedicated-9.5", "L-HA-dedicated-9.5", "L-HA-enc-dedicated-9.5")
      end

      describe "plan rds_properties" do
        shared_examples "all postgres plans" do
          let(:rds_properties) { subject.fetch("rds_properties") }

          it "uses postgres 9.5" do
            expect(rds_properties["engine_version"]).to eq("9.5")
          end
          it "uses solid state storage" do
            expect(rds_properties).to include("storage_type" => "gp2")
          end
          it "sets the db subnet group and security groups from terraform" do
            expect(rds_properties).to include(
              "db_subnet_group_name" => terraform_fixture("rds_broker_dbs_subnet_group"),
              "vpc_security_group_ids" => [terraform_fixture("rds_broker_dbs_security_group_id")],
            )
          end
        end

        shared_examples "free sized postgres plans" do
          it_behaves_like "all postgres plans"

          let(:rds_properties) { subject.fetch("rds_properties") }

          it { expect(rds_properties).to include("allocated_storage" => 5) }
          it { expect(rds_properties).to include("db_instance_class" => "db.t2.micro") }
        end

        shared_examples "small sized postgres plans" do
          it_behaves_like "all postgres plans"

          let(:rds_properties) { subject.fetch("rds_properties") }

          it { expect(rds_properties).to include("allocated_storage" => 20) }
          it { expect(rds_properties).to include("db_instance_class" => "db.t2.small") }
        end

        shared_examples "medium sized postgres plans" do
          it_behaves_like "all postgres plans"

          let(:rds_properties) { subject.fetch("rds_properties") }

          it { expect(rds_properties).to include("allocated_storage" => 20) }
          it { expect(rds_properties).to include("db_instance_class" => "db.m4.large") }
        end

        shared_examples "large sized postgres plans" do
          it_behaves_like "all postgres plans"

          let(:rds_properties) { subject.fetch("rds_properties") }

          it { expect(rds_properties).to include("allocated_storage" => 20) }
          it { expect(rds_properties).to include("db_instance_class" => "db.m4.2xlarge") }
        end

        shared_examples "backup enabled plans" do
          let(:rds_properties) { subject.fetch("rds_properties") }

          it "has a backup retention period of 7 days" do
            expect(rds_properties).to include(
              "backup_retention_period" => 7
            )
          end
        end

        shared_examples "backup disabled plans" do
          it "calls out that it's not backed up in the description" do
            expect(subject.fetch("description")).to include("NOT BACKED UP")
          end

          let(:rds_properties) { subject.fetch("rds_properties") }

          it "has all snapshots disabled" do
            expect(rds_properties).to include(
              "backup_retention_period" => 0,
              "skip_final_snapshot" => true,
            )
          end
        end

        shared_examples "HA plans" do
          let(:rds_properties) { subject.fetch("rds_properties") }
          it { expect(rds_properties).to include("multi_az" => true) }
        end

        shared_examples "non-HA plans" do
          let(:rds_properties) { subject.fetch("rds_properties") }
          it { expect(rds_properties).to include("multi_az" => false) }
        end

        shared_examples "Encryption disabled plans" do
          let(:rds_properties) { subject.fetch("rds_properties") }
          it { expect(rds_properties).to include("storage_encrypted" => false) }
        end

        shared_examples "Encryption enabled plans" do
          let(:rds_properties) { subject.fetch("rds_properties") }
          it { expect(rds_properties).to include("storage_encrypted" => true) }
        end

        describe "S-dedicated-9.5" do
          subject { pg_plans.find { |p| p["name"] == "S-dedicated-9.5" } }

          it_behaves_like "small sized postgres plans"
          it_behaves_like "backup enabled plans"
          it_behaves_like "non-HA plans"
          it_behaves_like "Encryption disabled plans"
        end

        describe "S-HA-dedicated-9.5" do
          subject { pg_plans.find { |p| p["name"] == "S-HA-dedicated-9.5" } }

          it_behaves_like "small sized postgres plans"
          it_behaves_like "backup enabled plans"
          it_behaves_like "HA plans"
          it_behaves_like "Encryption disabled plans"
        end

        describe "M-dedicated-9.5" do
          subject { pg_plans.find { |p| p["name"] == "M-dedicated-9.5" } }

          it_behaves_like "medium sized postgres plans"
          it_behaves_like "backup enabled plans"
          it_behaves_like "non-HA plans"
          it_behaves_like "Encryption disabled plans"
        end

        describe "M-HA-dedicated-9.5" do
          subject { pg_plans.find { |p| p["name"] == "M-HA-dedicated-9.5" } }

          it_behaves_like "medium sized postgres plans"
          it_behaves_like "backup enabled plans"
          it_behaves_like "HA plans"
          it_behaves_like "Encryption disabled plans"
        end

        describe "M-HA-enc-dedicated-9.5" do
          subject { pg_plans.find { |p| p["name"] == "M-HA-enc-dedicated-9.5" } }

          it_behaves_like "medium sized postgres plans"
          it_behaves_like "backup enabled plans"
          it_behaves_like "HA plans"
          it_behaves_like "Encryption enabled plans"
        end

        describe "L-dedicated-9.5" do
          subject { pg_plans.find { |p| p["name"] == "L-dedicated-9.5" } }

          it_behaves_like "large sized postgres plans"
          it_behaves_like "backup enabled plans"
          it_behaves_like "non-HA plans"
          it_behaves_like "Encryption disabled plans"
        end

        describe "L-HA-dedicated-9.5" do
          subject { pg_plans.find { |p| p["name"] == "L-HA-dedicated-9.5" } }

          it_behaves_like "large sized postgres plans"
          it_behaves_like "backup enabled plans"
          it_behaves_like "HA plans"
          it_behaves_like "Encryption disabled plans"
        end

        describe "L-HA-enc-dedicated-9.5" do
          subject { pg_plans.find { |p| p["name"] == "L-HA-enc-dedicated-9.5" } }

          it_behaves_like "large sized postgres plans"
          it_behaves_like "backup enabled plans"
          it_behaves_like "HA plans"
          it_behaves_like "Encryption enabled plans"
        end

        describe "free plan" do
          subject { pg_plans.find { |p| p["name"] == "Free" } }

          it "is marked as free" do
            expect(subject.fetch("free")).to eq(true)
          end

          it_behaves_like "free sized postgres plans"
          it_behaves_like "backup disabled plans"
          it_behaves_like "non-HA plans"
          it_behaves_like "Encryption disabled plans"
        end
      end
    end

    describe "mysql service" do
      let(:my_service) { services.find { |s| s["name"] == "mysql" } }
      let(:my_plans) { my_service.fetch("plans") }

      it "contains only specific plans" do
        my_plan_names = my_plans.map { |p| p["name"] }
        expect(my_plan_names).to contain_exactly("Free", "S-dedicated-5.7", "S-HA-dedicated-5.7", "M-dedicated-5.7", "M-HA-dedicated-5.7", "M-HA-enc-dedicated-5.7", "L-dedicated-5.7", "L-HA-dedicated-5.7", "L-HA-enc-dedicated-5.7")
      end

      describe "plan rds_properties" do
        shared_examples "all mysql plans" do
          let(:rds_properties) { subject.fetch("rds_properties") }

          it "uses MySQL 5.7" do
            expect(rds_properties["engine_version"]).to start_with("5.7")
          end
          it "uses solid state storage" do
            expect(rds_properties).to include("storage_type" => "gp2")
          end
          it "sets the db subnet group and security groups from terraform" do
            expect(rds_properties).to include(
              "db_subnet_group_name" => terraform_fixture("rds_broker_dbs_subnet_group"),
              "vpc_security_group_ids" => [terraform_fixture("rds_broker_dbs_security_group_id")],
            )
          end
        end

        shared_examples "free sized mysql plans" do
          it_behaves_like "all mysql plans"

          let(:rds_properties) { subject.fetch("rds_properties") }

          it { expect(rds_properties).to include("allocated_storage" => 5) }
          it { expect(rds_properties).to include("db_instance_class" => "db.t2.micro") }
        end

        shared_examples "small sized mysql plans" do
          it_behaves_like "all mysql plans"

          let(:rds_properties) { subject.fetch("rds_properties") }

          it { expect(rds_properties).to include("allocated_storage" => 20) }
          it { expect(rds_properties).to include("db_instance_class" => "db.t2.small") }
        end

        shared_examples "medium sized mysql plans" do
          it_behaves_like "all mysql plans"

          let(:rds_properties) { subject.fetch("rds_properties") }

          it { expect(rds_properties).to include("allocated_storage" => 20) }
          it { expect(rds_properties).to include("db_instance_class" => "db.m4.large") }
        end

        shared_examples "large sized mysql plans" do
          it_behaves_like "all mysql plans"

          let(:rds_properties) { subject.fetch("rds_properties") }

          it { expect(rds_properties).to include("allocated_storage" => 20) }
          it { expect(rds_properties).to include("db_instance_class" => "db.m4.2xlarge") }
        end

        shared_examples "backup enabled plans" do
          let(:rds_properties) { subject.fetch("rds_properties") }

          it "has a backup retention period of 7 days" do
            expect(rds_properties).to include(
              "backup_retention_period" => 7
            )
          end
        end

        shared_examples "backup disabled plans" do
          it "calls out that it's not backed up in the description" do
            expect(subject.fetch("description")).to include("NOT BACKED UP")
          end

          let(:rds_properties) { subject.fetch("rds_properties") }

          it "has all snapshots disabled" do
            expect(rds_properties).to include(
              "backup_retention_period" => 0,
              "skip_final_snapshot" => true,
            )
          end
        end

        shared_examples "HA plans" do
          let(:rds_properties) { subject.fetch("rds_properties") }
          it { expect(rds_properties).to include("multi_az" => true) }
        end

        shared_examples "non-HA plans" do
          let(:rds_properties) { subject.fetch("rds_properties") }
          it { expect(rds_properties).to include("multi_az" => false) }
        end

        shared_examples "Encryption disabled plans" do
          let(:rds_properties) { subject.fetch("rds_properties") }
          it { expect(rds_properties).to include("storage_encrypted" => false) }
        end

        shared_examples "Encryption enabled plans" do
          let(:rds_properties) { subject.fetch("rds_properties") }
          it { expect(rds_properties).to include("storage_encrypted" => true) }
        end

        describe "S-dedicated-5.7" do
          subject { my_plans.find { |p| p["name"] == "S-dedicated-5.7" } }

          it_behaves_like "small sized mysql plans"
          it_behaves_like "backup enabled plans"
          it_behaves_like "non-HA plans"
          it_behaves_like "Encryption disabled plans"
        end

        describe "S-HA-dedicated-5.7" do
          subject { my_plans.find { |p| p["name"] == "S-HA-dedicated-5.7" } }

          it_behaves_like "small sized mysql plans"
          it_behaves_like "backup enabled plans"
          it_behaves_like "HA plans"
          it_behaves_like "Encryption disabled plans"
        end

        describe "M-dedicated-5.7" do
          subject { my_plans.find { |p| p["name"] == "M-dedicated-5.7" } }

          it_behaves_like "medium sized mysql plans"
          it_behaves_like "backup enabled plans"
          it_behaves_like "non-HA plans"
          it_behaves_like "Encryption disabled plans"
        end

        describe "M-HA-dedicated-5.7" do
          subject { my_plans.find { |p| p["name"] == "M-HA-dedicated-5.7" } }

          it_behaves_like "medium sized mysql plans"
          it_behaves_like "backup enabled plans"
          it_behaves_like "HA plans"
          it_behaves_like "Encryption disabled plans"
        end

        describe "M-HA-enc-dedicated-5.7" do
          subject { my_plans.find { |p| p["name"] == "M-HA-enc-dedicated-5.7" } }

          it_behaves_like "medium sized mysql plans"
          it_behaves_like "backup enabled plans"
          it_behaves_like "HA plans"
          it_behaves_like "Encryption enabled plans"
        end

        describe "L-dedicated-5.7" do
          subject { my_plans.find { |p| p["name"] == "L-dedicated-5.7" } }

          it_behaves_like "large sized mysql plans"
          it_behaves_like "backup enabled plans"
          it_behaves_like "non-HA plans"
          it_behaves_like "Encryption disabled plans"
        end

        describe "L-HA-dedicated-5.7" do
          subject { my_plans.find { |p| p["name"] == "L-HA-dedicated-5.7" } }

          it_behaves_like "large sized mysql plans"
          it_behaves_like "backup enabled plans"
          it_behaves_like "HA plans"
          it_behaves_like "Encryption disabled plans"
        end

        describe "L-HA-enc-dedicated-5.7" do
          subject { my_plans.find { |p| p["name"] == "L-HA-enc-dedicated-5.7" } }

          it_behaves_like "large sized mysql plans"
          it_behaves_like "backup enabled plans"
          it_behaves_like "HA plans"
          it_behaves_like "Encryption enabled plans"
        end

        describe "free plan" do
          subject { my_plans.find { |p| p["name"] == "Free" } }

          it "is marked as free" do
            expect(subject.fetch("free")).to eq(true)
          end

          it_behaves_like "free sized mysql plans"
          it_behaves_like "backup disabled plans"
          it_behaves_like "non-HA plans"
          it_behaves_like "Encryption disabled plans"
        end
      end
    end
  end
end
