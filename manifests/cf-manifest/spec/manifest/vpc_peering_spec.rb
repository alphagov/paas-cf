RSpec.describe "VPC peering" do
  let(:properties) { property_tree(manifest.fetch("instance_groups.api.jobs.cloud_controller_ng.properties")) }

  describe "when in a default non-production environment" do
    let(:manifest) { manifest_with_defaults }

    it "does not add additional security groups" do
      expect(properties.fetch("cc.security_group_definitions.vpc_peer_dit", "not_found")).to eq "not_found"
    end
  end
end
