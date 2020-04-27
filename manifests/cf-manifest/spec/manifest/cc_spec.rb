RSpec.describe "cloud controller" do
  context "limits" do
    let(:manifest) { manifest_with_defaults }
    let(:cc_ng_props) { manifest.fetch("instance_groups.api.jobs.cloud_controller_ng.properties.cc") }
    let(:cc_worker_props) { manifest.fetch("instance_groups.cc-worker.jobs.cloud_controller_worker.properties.cc") }

    it "should be the same maximum app disk for worker and api" do
      expect(cc_ng_props['maximum_app_disk_in_mb']).to be == cc_worker_props['maximum_app_disk_in_mb']
    end

    it "should be the same maximum app healthcheck timeout for worker and api" do
      expect(cc_ng_props['maximum_health_check_timeout']).to be == cc_worker_props['maximum_health_check_timeout']
    end
  end

  context "worker" do
    context("dev") do
      let(:manifest) { manifest_for_dev }
      let(:cc_worker) { manifest.fetch("instance_groups.cc-worker") }

      it "has 2 instances" do
        expect(cc_worker['instances']).to be == 2
      end
    end

    context("prod") do
      let(:manifest) { manifest_for_env("prod") }
      let(:cc_worker) { manifest.fetch("instance_groups.cc-worker") }

      it "has more instances" do
        expect(cc_worker['instances']).to be > 2
      end
    end

    context("prod-lon") do
      let(:manifest) { manifest_for_env("prod-lon") }
      let(:cc_worker) { manifest.fetch("instance_groups.cc-worker") }

      it "has more instances" do
        expect(cc_worker['instances']).to be > 2
      end
    end
  end
end
