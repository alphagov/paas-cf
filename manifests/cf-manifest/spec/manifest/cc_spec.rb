RSpec.describe "cloud controller" do
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
