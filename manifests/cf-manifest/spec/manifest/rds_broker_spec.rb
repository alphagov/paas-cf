
RSpec.describe "RDS broker properties" do
  let(:manifest) { manifest_without_vars_store }

  describe "adding RDS access to application security groups" do
    it "appends a security group definition" do
      defs = manifest.fetch("instance_groups.api.jobs.cloud_controller_ng.properties.cc.security_group_definitions")
      expect(defs.length).to be > 1 # Ensure the default ones haven't been replaced
      rds_sg = defs.find { |d| d["name"] == "rds_broker_instances" }
      expect(rds_sg).to be
      expect(rds_sg["rules"]).to eq([{
        "protocol" => "tcp",
        "destination" => terraform_fixture_value("aws_backing_service_cidr_all"),
        "ports" => "5432",
      }, {
        "protocol" => "tcp",
        "destination" => terraform_fixture_value("aws_backing_service_cidr_all"),
        "ports" => "3306",
      }])
    end

    it "adds to default_running_security_groups" do
      sgs = manifest.fetch("instance_groups.api.jobs.cloud_controller_ng.properties.cc.default_running_security_groups")
      expect(sgs.length).to be > 1 # Ensure the default ones haven't been replaced
      expect(sgs).to include("rds_broker_instances")
    end

    it "adds to default_staging_security_groups" do
      sgs = manifest.fetch("instance_groups.api.jobs.cloud_controller_ng.properties.cc.default_staging_security_groups")
      expect(sgs.length).to be > 1 # Ensure the default ones haven't been replaced
      expect(sgs).to include("rds_broker_instances")
    end
  end

  describe "service plans" do
    let(:rds_broker_instance_group) {
      manifest.fetch("instance_groups.rds_broker")
    }
    let(:services) {
      manifest.fetch("instance_groups.rds_broker.jobs.rds-broker.properties.rds-broker.catalog.services")
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

    shared_examples "tiny sized t2 class plans" do
      let(:rds_properties) { subject.fetch("rds_properties") }

      it { expect(rds_properties).to include("allocated_storage" => 5) }
      it { expect(rds_properties).to include("db_instance_class" => "db.t2.micro") }
    end

    shared_examples "tiny sized t3 class plans" do
      let(:rds_properties) { subject.fetch("rds_properties") }

      it { expect(rds_properties).to include("allocated_storage" => 5) }
      it { expect(rds_properties).to include("db_instance_class" => "db.t3.micro") }
    end

    shared_examples "small sized t2 class plans" do
      let(:rds_properties) { subject.fetch("rds_properties") }

      it { expect(rds_properties).to include("allocated_storage" => 20) }
      it { expect(rds_properties).to include("db_instance_class" => "db.t2.small") }
    end

    shared_examples "small sized t3 class plans" do
      let(:rds_properties) { subject.fetch("rds_properties") }

      it { expect(rds_properties).to include("allocated_storage" => 100) }
      it { expect(rds_properties).to include("db_instance_class" => "db.t3.small") }
    end

    shared_examples "medium sized m4 class plans" do
      let(:rds_properties) { subject.fetch("rds_properties") }

      it { expect(rds_properties).to include("allocated_storage" => 100) }
      it { expect(rds_properties).to include("db_instance_class" => "db.m4.large") }
    end

    shared_examples "medium sized m5 class plans" do
      let(:rds_properties) { subject.fetch("rds_properties") }

      it { expect(rds_properties).to include("allocated_storage" => 100) }
      it { expect(rds_properties).to include("db_instance_class" => "db.m5.large") }
    end

    shared_examples "large sized m4 class plans" do
      let(:rds_properties) { subject.fetch("rds_properties") }

      it { expect(rds_properties).to include("allocated_storage" => 512) }
      it { expect(rds_properties).to include("db_instance_class" => "db.m4.2xlarge") }
    end

    shared_examples "large sized m5 class plans" do
      let(:rds_properties) { subject.fetch("rds_properties") }

      it { expect(rds_properties).to include("allocated_storage" => 512) }
      it { expect(rds_properties).to include("db_instance_class" => "db.m5.2xlarge") }
    end

    shared_examples "xlarge sized m4 class plans" do
      let(:rds_properties) { subject.fetch("rds_properties") }

      it { expect(rds_properties).to include("allocated_storage" => 2048) }
      it { expect(rds_properties).to include("db_instance_class" => "db.m4.4xlarge") }
    end

    shared_examples "xlarge sized m5 class plans" do
      let(:rds_properties) { subject.fetch("rds_properties") }

      it { expect(rds_properties).to include("allocated_storage" => 2048) }
      it { expect(rds_properties).to include("db_instance_class" => "db.m5.4xlarge") }
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

    describe "postgres service" do
      let(:pg_service) { services.find { |s| s["name"] == "postgres" } }
      let(:pg_plans) { pg_service.fetch("plans") }

      it "contains only specific plans" do
        pg_plan_names = pg_plans.map { |p| p["name"] }
        expect(pg_plan_names).to contain_exactly(
          "tiny-unencrypted-9.5",
          "small-unencrypted-9.5",
          "small-9.5",
          "small-ha-unencrypted-9.5",
          "small-ha-9.5",
          "medium-unencrypted-9.5",
          "medium-9.5",
          "medium-ha-unencrypted-9.5",
          "medium-ha-9.5",
          "large-unencrypted-9.5",
          "large-9.5",
          "large-ha-unencrypted-9.5",
          "large-ha-9.5",
          "xlarge-unencrypted-9.5",
          "xlarge-9.5",
          "xlarge-ha-unencrypted-9.5",
          "xlarge-ha-9.5",
          "tiny-unencrypted-10",
          "small-10",
          "small-ha-10",
          "medium-10",
          "medium-ha-10",
          "large-10",
          "large-ha-10",
          "xlarge-10",
          "xlarge-ha-10",
        )
      end

      describe "plan rds_properties" do
        shared_examples "all postgres plans" do
          let(:rds_properties) { subject.fetch("rds_properties") }

          it "uses solid state storage" do
            expect(rds_properties).to include("storage_type" => "gp2")
          end
          it "sets the db subnet group and security groups from terraform" do
            expect(rds_properties).to include(
              "db_subnet_group_name" => terraform_fixture_value("rds_broker_dbs_subnet_group"),
              "vpc_security_group_ids" => [terraform_fixture_value("rds_broker_dbs_security_group_id")],
            )
          end
        end

        shared_examples "postgres 9.5 plans" do
          let(:rds_properties) { subject.fetch("rds_properties") }

          it "uses postgres 9.5" do
            expect(rds_properties["engine_version"]).to eq("9.5")
          end
        end

        shared_examples "postgres 10 plans" do
          let(:rds_properties) { subject.fetch("rds_properties") }

          it "uses postgres 10" do
            expect(rds_properties["engine_version"]).to eq("10")
          end
        end

        describe "tiny-unencrypted-9.5" do
          subject { pg_plans.find { |p| p["name"] == "tiny-unencrypted-9.5" } }

          it "is marked as free" do
            expect(subject.fetch("free")).to eq(true)
          end

          it_behaves_like "all postgres plans"
          it_behaves_like "postgres 9.5 plans"
          it_behaves_like "tiny sized t2 class plans"
          it_behaves_like "backup disabled plans"
          it_behaves_like "non-HA plans"
          it_behaves_like "Encryption disabled plans"
        end

        describe "small-unencrypted-9.5" do
          subject { pg_plans.find { |p| p["name"] == "small-unencrypted-9.5" } }

          it_behaves_like "all postgres plans"
          it_behaves_like "postgres 9.5 plans"
          it_behaves_like "small sized t2 class plans"
          it_behaves_like "backup enabled plans"
          it_behaves_like "non-HA plans"
          it_behaves_like "Encryption disabled plans"
        end

        describe "small-9.5" do
          subject { pg_plans.find { |p| p["name"] == "small-9.5" } }

          it_behaves_like "all postgres plans"
          it_behaves_like "postgres 9.5 plans"
          it_behaves_like "small sized t2 class plans"
          it_behaves_like "backup enabled plans"
          it_behaves_like "non-HA plans"
          it_behaves_like "Encryption enabled plans"
        end

        describe "small-ha-unencrypted-9.5" do
          subject { pg_plans.find { |p| p["name"] == "small-ha-unencrypted-9.5" } }

          it_behaves_like "all postgres plans"
          it_behaves_like "postgres 9.5 plans"
          it_behaves_like "small sized t2 class plans"
          it_behaves_like "backup enabled plans"
          it_behaves_like "HA plans"
          it_behaves_like "Encryption disabled plans"
        end

        describe "small-ha-9.5" do
          subject { pg_plans.find { |p| p["name"] == "small-ha-9.5" } }

          it_behaves_like "all postgres plans"
          it_behaves_like "postgres 9.5 plans"
          it_behaves_like "small sized t2 class plans"
          it_behaves_like "backup enabled plans"
          it_behaves_like "HA plans"
          it_behaves_like "Encryption enabled plans"
        end

        describe "medium-unencrypted-9.5" do
          subject { pg_plans.find { |p| p["name"] == "medium-unencrypted-9.5" } }

          it_behaves_like "all postgres plans"
          it_behaves_like "postgres 9.5 plans"
          it_behaves_like "medium sized m4 class plans"
          it_behaves_like "backup enabled plans"
          it_behaves_like "non-HA plans"
          it_behaves_like "Encryption disabled plans"
        end

        describe "medium-9.5" do
          subject { pg_plans.find { |p| p["name"] == "medium-9.5" } }

          it_behaves_like "all postgres plans"
          it_behaves_like "postgres 9.5 plans"
          it_behaves_like "medium sized m4 class plans"
          it_behaves_like "backup enabled plans"
          it_behaves_like "non-HA plans"
          it_behaves_like "Encryption enabled plans"
        end

        describe "medium-ha-unencrypted-9.5" do
          subject { pg_plans.find { |p| p["name"] == "medium-ha-unencrypted-9.5" } }

          it_behaves_like "all postgres plans"
          it_behaves_like "postgres 9.5 plans"
          it_behaves_like "medium sized m4 class plans"
          it_behaves_like "backup enabled plans"
          it_behaves_like "HA plans"
          it_behaves_like "Encryption disabled plans"
        end

        describe "medium-ha-9.5" do
          subject { pg_plans.find { |p| p["name"] == "medium-ha-9.5" } }

          it_behaves_like "all postgres plans"
          it_behaves_like "postgres 9.5 plans"
          it_behaves_like "medium sized m4 class plans"
          it_behaves_like "backup enabled plans"
          it_behaves_like "HA plans"
          it_behaves_like "Encryption enabled plans"
        end

        describe "large-unencrypted-9.5" do
          subject { pg_plans.find { |p| p["name"] == "large-unencrypted-9.5" } }

          it_behaves_like "all postgres plans"
          it_behaves_like "postgres 9.5 plans"
          it_behaves_like "large sized m4 class plans"
          it_behaves_like "backup enabled plans"
          it_behaves_like "non-HA plans"
          it_behaves_like "Encryption disabled plans"
        end

        describe "large-9.5" do
          subject { pg_plans.find { |p| p["name"] == "large-9.5" } }

          it_behaves_like "all postgres plans"
          it_behaves_like "postgres 9.5 plans"
          it_behaves_like "large sized m4 class plans"
          it_behaves_like "backup enabled plans"
          it_behaves_like "non-HA plans"
          it_behaves_like "Encryption enabled plans"
        end

        describe "large-ha-unencrypted-9.5" do
          subject { pg_plans.find { |p| p["name"] == "large-ha-unencrypted-9.5" } }

          it_behaves_like "all postgres plans"
          it_behaves_like "postgres 9.5 plans"
          it_behaves_like "large sized m4 class plans"
          it_behaves_like "backup enabled plans"
          it_behaves_like "HA plans"
          it_behaves_like "Encryption disabled plans"
        end

        describe "large-ha-9.5" do
          subject { pg_plans.find { |p| p["name"] == "large-ha-9.5" } }

          it_behaves_like "all postgres plans"
          it_behaves_like "postgres 9.5 plans"
          it_behaves_like "large sized m4 class plans"
          it_behaves_like "backup enabled plans"
          it_behaves_like "HA plans"
          it_behaves_like "Encryption enabled plans"
        end

        describe "xlarge-unencrypted-9.5" do
          subject { pg_plans.find { |p| p["name"] == "xlarge-unencrypted-9.5" } }

          it_behaves_like "all postgres plans"
          it_behaves_like "postgres 9.5 plans"
          it_behaves_like "xlarge sized m4 class plans"
          it_behaves_like "backup enabled plans"
          it_behaves_like "non-HA plans"
          it_behaves_like "Encryption disabled plans"
        end

        describe "xlarge-9.5" do
          subject { pg_plans.find { |p| p["name"] == "xlarge-9.5" } }

          it_behaves_like "all postgres plans"
          it_behaves_like "postgres 9.5 plans"
          it_behaves_like "xlarge sized m4 class plans"
          it_behaves_like "backup enabled plans"
          it_behaves_like "non-HA plans"
          it_behaves_like "Encryption enabled plans"
        end

        describe "xlarge-ha-unencrypted-9.5" do
          subject { pg_plans.find { |p| p["name"] == "xlarge-ha-unencrypted-9.5" } }

          it_behaves_like "all postgres plans"
          it_behaves_like "postgres 9.5 plans"
          it_behaves_like "xlarge sized m4 class plans"
          it_behaves_like "backup enabled plans"
          it_behaves_like "HA plans"
          it_behaves_like "Encryption disabled plans"
        end

        describe "xlarge-ha-9.5" do
          subject { pg_plans.find { |p| p["name"] == "xlarge-ha-9.5" } }

          it_behaves_like "all postgres plans"
          it_behaves_like "postgres 9.5 plans"
          it_behaves_like "xlarge sized m4 class plans"
          it_behaves_like "backup enabled plans"
          it_behaves_like "HA plans"
          it_behaves_like "Encryption enabled plans"
        end

        # Postgres 10
        describe "tiny-unencrypted-10" do
          subject { pg_plans.find { |p| p["name"] == "tiny-unencrypted-10" } }

          it "is marked as free" do
            expect(subject.fetch("free")).to eq(true)
          end

          it_behaves_like "all postgres plans"
          it_behaves_like "postgres 10 plans"
          it_behaves_like "tiny sized t2 class plans"
          it_behaves_like "backup disabled plans"
          it_behaves_like "non-HA plans"
          it_behaves_like "Encryption disabled plans"
        end

        describe "small-10" do
          subject { pg_plans.find { |p| p["name"] == "small-10" } }

          it_behaves_like "all postgres plans"
          it_behaves_like "postgres 10 plans"
          it_behaves_like "small sized t2 class plans"
          it_behaves_like "backup enabled plans"
          it_behaves_like "non-HA plans"
          it_behaves_like "Encryption enabled plans"
        end

        describe "small-ha-10" do
          subject { pg_plans.find { |p| p["name"] == "small-ha-10" } }

          it_behaves_like "all postgres plans"
          it_behaves_like "postgres 10 plans"
          it_behaves_like "small sized t2 class plans"
          it_behaves_like "backup enabled plans"
          it_behaves_like "HA plans"
          it_behaves_like "Encryption enabled plans"
        end

        describe "medium-10" do
          subject { pg_plans.find { |p| p["name"] == "medium-10" } }

          it_behaves_like "all postgres plans"
          it_behaves_like "postgres 10 plans"
          it_behaves_like "medium sized m4 class plans"
          it_behaves_like "backup enabled plans"
          it_behaves_like "non-HA plans"
          it_behaves_like "Encryption enabled plans"
        end

        describe "medium-ha-10" do
          subject { pg_plans.find { |p| p["name"] == "medium-ha-10" } }

          it_behaves_like "all postgres plans"
          it_behaves_like "postgres 10 plans"
          it_behaves_like "medium sized m4 class plans"
          it_behaves_like "backup enabled plans"
          it_behaves_like "HA plans"
          it_behaves_like "Encryption enabled plans"
        end

        describe "large-10" do
          subject { pg_plans.find { |p| p["name"] == "large-10" } }

          it_behaves_like "all postgres plans"
          it_behaves_like "postgres 10 plans"
          it_behaves_like "large sized m4 class plans"
          it_behaves_like "backup enabled plans"
          it_behaves_like "non-HA plans"
          it_behaves_like "Encryption enabled plans"
        end

        describe "large-ha-10" do
          subject { pg_plans.find { |p| p["name"] == "large-ha-10" } }

          it_behaves_like "all postgres plans"
          it_behaves_like "postgres 10 plans"
          it_behaves_like "large sized m4 class plans"
          it_behaves_like "backup enabled plans"
          it_behaves_like "HA plans"
          it_behaves_like "Encryption enabled plans"
        end

        describe "xlarge-10" do
          subject { pg_plans.find { |p| p["name"] == "xlarge-10" } }

          it_behaves_like "all postgres plans"
          it_behaves_like "postgres 10 plans"
          it_behaves_like "xlarge sized m4 class plans"
          it_behaves_like "backup enabled plans"
          it_behaves_like "non-HA plans"
          it_behaves_like "Encryption enabled plans"
        end

        describe "xlarge-ha-10" do
          subject { pg_plans.find { |p| p["name"] == "xlarge-ha-10" } }

          it_behaves_like "all postgres plans"
          it_behaves_like "postgres 10 plans"
          it_behaves_like "xlarge sized m4 class plans"
          it_behaves_like "backup enabled plans"
          it_behaves_like "HA plans"
          it_behaves_like "Encryption enabled plans"
        end
      end
    end

    describe "mysql service" do
      let(:my_service) { services.find { |s| s["name"] == "mysql" } }
      let(:my_plans) { my_service.fetch("plans") }

      it "contains only specific plans" do
        my_plan_names = my_plans.map { |p| p["name"] }
        expect(my_plan_names).to contain_exactly(
          "tiny-unencrypted-5.7",
          "small-unencrypted-5.7",
          "small-5.7",
          "small-ha-unencrypted-5.7",
          "small-ha-5.7",
          "medium-unencrypted-5.7",
          "medium-5.7",
          "medium-ha-unencrypted-5.7",
          "medium-ha-5.7",
          "large-unencrypted-5.7",
          "large-5.7",
          "large-ha-unencrypted-5.7",
          "large-ha-5.7",
          "xlarge-unencrypted-5.7",
          "xlarge-5.7",
          "xlarge-ha-unencrypted-5.7",
          "xlarge-ha-5.7",
          "tiny-unencrypted-8.0",
          "small-8.0",
          "small-ha-8.0",
          "medium-8.0",
          "medium-ha-8.0",
          "large-8.0",
          "large-ha-8.0",
          "xlarge-8.0",
          "xlarge-ha-8.0",
        )
      end

      describe "plan rds_properties" do
        shared_examples "all mysql 5.7 plans" do
          let(:rds_properties) { subject.fetch("rds_properties") }

          it "uses MySQL 5.7" do
            expect(rds_properties["engine_version"]).to start_with("5.7")
          end
          it "uses solid state storage" do
            expect(rds_properties).to include("storage_type" => "gp2")
          end
          it "sets the db subnet group and security groups from terraform" do
            expect(rds_properties).to include(
              "db_subnet_group_name" => terraform_fixture_value("rds_broker_dbs_subnet_group"),
              "vpc_security_group_ids" => [terraform_fixture_value("rds_broker_dbs_security_group_id")],
            )
          end
        end

        shared_examples "all mysql 8.0 plans" do
          let(:rds_properties) { subject.fetch("rds_properties") }

          it "uses MySQL 8.0" do
            expect(rds_properties["engine_version"]).to start_with("8.0")
          end
          it "uses solid state storage" do
            expect(rds_properties).to include("storage_type" => "gp2")
          end
          it "sets the db subnet group and security groups from terraform" do
            expect(rds_properties).to include(
              "db_subnet_group_name" => terraform_fixture_value("rds_broker_dbs_subnet_group"),
              "vpc_security_group_ids" => [terraform_fixture_value("rds_broker_dbs_security_group_id")],
            )
          end
        end


        describe "tiny-unencrypted-5.7" do
          subject { my_plans.find { |p| p["name"] == "tiny-unencrypted-5.7" } }

          it "is marked as free" do
            expect(subject.fetch("free")).to eq(true)
          end

          it_behaves_like "all mysql 5.7 plans"
          it_behaves_like "tiny sized t2 class plans"
          it_behaves_like "backup disabled plans"
          it_behaves_like "non-HA plans"
          it_behaves_like "Encryption disabled plans"
        end

        describe "small-unencrypted-5.7" do
          subject { my_plans.find { |p| p["name"] == "small-unencrypted-5.7" } }

          it_behaves_like "all mysql 5.7 plans"
          it_behaves_like "small sized t2 class plans"
          it_behaves_like "backup enabled plans"
          it_behaves_like "non-HA plans"
          it_behaves_like "Encryption disabled plans"
        end

        describe "small-5.7" do
          subject { my_plans.find { |p| p["name"] == "small-5.7" } }

          it_behaves_like "all mysql 5.7 plans"
          it_behaves_like "small sized t2 class plans"
          it_behaves_like "backup enabled plans"
          it_behaves_like "non-HA plans"
          it_behaves_like "Encryption enabled plans"
        end

        describe "small-ha-unencrypted-5.7" do
          subject { my_plans.find { |p| p["name"] == "small-ha-unencrypted-5.7" } }

          it_behaves_like "all mysql 5.7 plans"
          it_behaves_like "small sized t2 class plans"
          it_behaves_like "backup enabled plans"
          it_behaves_like "HA plans"
          it_behaves_like "Encryption disabled plans"
        end

        describe "small-ha-5.7" do
          subject { my_plans.find { |p| p["name"] == "small-ha-5.7" } }

          it_behaves_like "all mysql 5.7 plans"
          it_behaves_like "small sized t2 class plans"
          it_behaves_like "backup enabled plans"
          it_behaves_like "HA plans"
          it_behaves_like "Encryption enabled plans"
        end

        describe "medium-unencrypted-5.7" do
          subject { my_plans.find { |p| p["name"] == "medium-unencrypted-5.7" } }

          it_behaves_like "all mysql 5.7 plans"
          it_behaves_like "medium sized m4 class plans"
          it_behaves_like "backup enabled plans"
          it_behaves_like "non-HA plans"
          it_behaves_like "Encryption disabled plans"
        end

        describe "medium-5.7" do
          subject { my_plans.find { |p| p["name"] == "medium-5.7" } }

          it_behaves_like "all mysql 5.7 plans"
          it_behaves_like "medium sized m4 class plans"
          it_behaves_like "backup enabled plans"
          it_behaves_like "non-HA plans"
          it_behaves_like "Encryption enabled plans"
        end

        describe "medium-ha-unencrypted-5.7" do
          subject { my_plans.find { |p| p["name"] == "medium-ha-unencrypted-5.7" } }

          it_behaves_like "all mysql 5.7 plans"
          it_behaves_like "medium sized m4 class plans"
          it_behaves_like "backup enabled plans"
          it_behaves_like "HA plans"
          it_behaves_like "Encryption disabled plans"
        end

        describe "medium-ha-5.7" do
          subject { my_plans.find { |p| p["name"] == "medium-ha-5.7" } }

          it_behaves_like "all mysql 5.7 plans"
          it_behaves_like "medium sized m4 class plans"
          it_behaves_like "backup enabled plans"
          it_behaves_like "HA plans"
          it_behaves_like "Encryption enabled plans"
        end

        describe "large-unencrypted-5.7" do
          subject { my_plans.find { |p| p["name"] == "large-unencrypted-5.7" } }

          it_behaves_like "all mysql 5.7 plans"
          it_behaves_like "large sized m4 class plans"
          it_behaves_like "backup enabled plans"
          it_behaves_like "non-HA plans"
          it_behaves_like "Encryption disabled plans"
        end

        describe "large-5.7" do
          subject { my_plans.find { |p| p["name"] == "large-5.7" } }

          it_behaves_like "all mysql 5.7 plans"
          it_behaves_like "large sized m4 class plans"
          it_behaves_like "backup enabled plans"
          it_behaves_like "non-HA plans"
          it_behaves_like "Encryption enabled plans"
        end

        describe "large-ha-unencrypted-5.7" do
          subject { my_plans.find { |p| p["name"] == "large-ha-unencrypted-5.7" } }

          it_behaves_like "all mysql 5.7 plans"
          it_behaves_like "large sized m4 class plans"
          it_behaves_like "backup enabled plans"
          it_behaves_like "HA plans"
          it_behaves_like "Encryption disabled plans"
        end

        describe "large-ha-5.7" do
          subject { my_plans.find { |p| p["name"] == "large-ha-5.7" } }

          it_behaves_like "all mysql 5.7 plans"
          it_behaves_like "large sized m4 class plans"
          it_behaves_like "backup enabled plans"
          it_behaves_like "HA plans"
          it_behaves_like "Encryption enabled plans"
        end

        describe "xlarge-unencrypted-5.7" do
          subject { my_plans.find { |p| p["name"] == "xlarge-unencrypted-5.7" } }

          it_behaves_like "all mysql 5.7 plans"
          it_behaves_like "xlarge sized m4 class plans"
          it_behaves_like "backup enabled plans"
          it_behaves_like "non-HA plans"
          it_behaves_like "Encryption disabled plans"
        end

        describe "xlarge-5.7" do
          subject { my_plans.find { |p| p["name"] == "xlarge-5.7" } }

          it_behaves_like "all mysql 5.7 plans"
          it_behaves_like "xlarge sized m4 class plans"
          it_behaves_like "backup enabled plans"
          it_behaves_like "non-HA plans"
          it_behaves_like "Encryption enabled plans"
        end

        describe "xlarge-ha-unencrypted-5.7" do
          subject { my_plans.find { |p| p["name"] == "xlarge-ha-unencrypted-5.7" } }

          it_behaves_like "all mysql 5.7 plans"
          it_behaves_like "xlarge sized m4 class plans"
          it_behaves_like "backup enabled plans"
          it_behaves_like "HA plans"
          it_behaves_like "Encryption disabled plans"
        end

        describe "xlarge-ha-5.7" do
          subject { my_plans.find { |p| p["name"] == "xlarge-ha-5.7" } }

          it_behaves_like "all mysql 5.7 plans"
          it_behaves_like "xlarge sized m4 class plans"
          it_behaves_like "backup enabled plans"
          it_behaves_like "HA plans"
          it_behaves_like "Encryption enabled plans"
        end

        describe "tiny-unencrypted-8.0" do
          subject { my_plans.find { |p| p["name"] == "tiny-unencrypted-8.0" } }

          it "is marked as free" do
            expect(subject.fetch("free")).to eq(true)
          end

          it_behaves_like "all mysql 8.0 plans"
          it_behaves_like "tiny sized t3 class plans"
          it_behaves_like "backup disabled plans"
          it_behaves_like "non-HA plans"
          it_behaves_like "Encryption disabled plans"
        end

        describe "small-8.0" do
          subject { my_plans.find { |p| p["name"] == "small-8.0" } }

          it_behaves_like "all mysql 8.0 plans"
          it_behaves_like "small sized t3 class plans"
          it_behaves_like "backup enabled plans"
          it_behaves_like "non-HA plans"
          it_behaves_like "Encryption enabled plans"
        end

        describe "small-ha-8.0" do
          subject { my_plans.find { |p| p["name"] == "small-ha-8.0" } }

          it_behaves_like "all mysql 8.0 plans"
          it_behaves_like "small sized t3 class plans"
          it_behaves_like "backup enabled plans"
          it_behaves_like "HA plans"
          it_behaves_like "Encryption enabled plans"
        end

        describe "medium-8.0" do
          subject { my_plans.find { |p| p["name"] == "medium-8.0" } }

          it_behaves_like "all mysql 8.0 plans"
          it_behaves_like "medium sized m5 class plans"
          it_behaves_like "backup enabled plans"
          it_behaves_like "non-HA plans"
          it_behaves_like "Encryption enabled plans"
        end

        describe "medium-ha-8.0" do
          subject { my_plans.find { |p| p["name"] == "medium-ha-8.0" } }

          it_behaves_like "all mysql 8.0 plans"
          it_behaves_like "medium sized m5 class plans"
          it_behaves_like "backup enabled plans"
          it_behaves_like "HA plans"
          it_behaves_like "Encryption enabled plans"
        end

        describe "large-8.0" do
          subject { my_plans.find { |p| p["name"] == "large-8.0" } }

          it_behaves_like "all mysql 8.0 plans"
          it_behaves_like "large sized m5 class plans"
          it_behaves_like "backup enabled plans"
          it_behaves_like "non-HA plans"
          it_behaves_like "Encryption enabled plans"
        end

        describe "large-ha-8.0" do
          subject { my_plans.find { |p| p["name"] == "large-ha-8.0" } }

          it_behaves_like "all mysql 8.0 plans"
          it_behaves_like "large sized m5 class plans"
          it_behaves_like "backup enabled plans"
          it_behaves_like "HA plans"
          it_behaves_like "Encryption enabled plans"
        end

        describe "xlarge-8.0" do
          subject { my_plans.find { |p| p["name"] == "xlarge-8.0" } }

          it_behaves_like "all mysql 8.0 plans"
          it_behaves_like "xlarge sized m5 class plans"
          it_behaves_like "backup enabled plans"
          it_behaves_like "non-HA plans"
          it_behaves_like "Encryption enabled plans"
        end

        describe "xlarge-ha-8.0" do
          subject { my_plans.find { |p| p["name"] == "xlarge-ha-8.0" } }

          it_behaves_like "all mysql 8.0 plans"
          it_behaves_like "xlarge sized m5 class plans"
          it_behaves_like "backup enabled plans"
          it_behaves_like "HA plans"
          it_behaves_like "Encryption enabled plans"
        end
      end
    end
  end
end
