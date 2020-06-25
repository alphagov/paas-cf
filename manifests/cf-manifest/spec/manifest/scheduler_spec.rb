RSpec.describe "scheduler" do
  let(:manifest) { manifest_with_defaults }
  let(:instance_groups) { manifest.fetch("instance_groups") }

  let(:scheduler_instance_group) { manifest.fetch("instance_groups.scheduler") }

  describe "instance_group" do
    describe "when the deployment is stg-lon" do
      subject { manifest_for_env("stg-lon").fetch("instance_groups.scheduler") }

      it_behaves_like("a highly available instance group", min_instances: 3)
    end

    context "when the deployment is prod" do
      subject { manifest_for_env("prod").fetch("instance_groups.scheduler") }

      it_behaves_like("a highly available instance group", min_instances: 3)
    end

    context "when the deployment is prod-lon" do
      subject { manifest_for_env("prod-lon").fetch("instance_groups.scheduler") }

      it_behaves_like("a highly available instance group", min_instances: 3)
    end
  end
end
