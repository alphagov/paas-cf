RSpec.describe "cloud controller" do
  context "limits" do
    let(:manifest) { manifest_with_defaults }
    let(:cc_ng_props) { manifest.fetch("instance_groups.api.jobs.cloud_controller_ng.properties.cc") }
    let(:cc_worker_props) { manifest.fetch("instance_groups.cc-worker.jobs.cloud_controller_worker.properties.cc") }
    let(:cc_clock_props) { manifest.fetch("instance_groups.scheduler.jobs.cloud_controller_clock.properties.cc") }
    let(:cc_deployment_updater_props) { manifest.fetch("instance_groups.scheduler.jobs.cc_deployment_updater.properties.cc") }

    it "is the same maximum app disk for clock and worker and api and deployment updater" do
      expect(cc_ng_props["maximum_app_disk_in_mb"]).to be == cc_worker_props["maximum_app_disk_in_mb"]
      expect(cc_ng_props["maximum_app_disk_in_mb"]).to be == cc_clock_props["maximum_app_disk_in_mb"]
      expect(cc_ng_props["maximum_app_disk_in_mb"]).to be == cc_deployment_updater_props["maximum_app_disk_in_mb"]
    end

    it "is the same maximum app healthcheck timeout for clock and worker and api" do
      expect(cc_ng_props["maximum_health_check_timeout"]).to be == cc_worker_props["maximum_health_check_timeout"]
      expect(cc_ng_props["maximum_health_check_timeout"]).to be == cc_clock_props["maximum_health_check_timeout"]
    end
  end

  context "broker" do
    let(:manifest) { manifest_with_defaults }
    let(:cc_ng_props) { manifest.fetch("instance_groups.api.jobs.cloud_controller_ng.properties.cc") }
    let(:cc_worker_props) { manifest.fetch("instance_groups.cc-worker.jobs.cloud_controller_worker.properties.cc") }

    it "is the same broker client timeout for worker and api" do
      # clock does not have this property
      expect(cc_ng_props["broker_client_timeout_seconds"]).to be == cc_worker_props["broker_client_timeout_seconds"]
    end
  end

  context "worker" do
    context("dev") do
      let(:manifest) { manifest_for_dev }
      let(:cc_worker) { manifest.fetch("instance_groups.cc-worker") }

      it "has 2 instances" do
        expect(cc_worker["instances"]).to be == 2
      end
    end

    context("prod") do
      let(:manifest) { manifest_for_env("prod") }
      let(:cc_worker) { manifest.fetch("instance_groups.cc-worker") }

      it "has more instances" do
        expect(cc_worker["instances"]).to be > 2
      end
    end

    context("prod-lon") do
      let(:manifest) { manifest_for_env("prod-lon") }
      let(:cc_worker) { manifest.fetch("instance_groups.cc-worker") }

      it "has more instances" do
        expect(cc_worker["instances"]).to be > 2
      end
    end
  end
end
