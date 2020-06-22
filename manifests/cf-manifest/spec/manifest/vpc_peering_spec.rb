RSpec.describe "VPC peering" do
  let(:properties) { property_tree(manifest.fetch("instance_groups.api.jobs.cloud_controller_ng.properties")) }

  describe "when environment is not prod" do
    let(:manifest) { manifest_with_defaults }

    it "does not add additional security groups" do
      expect(properties.fetch("cc.security_group_definitions.vpc_peer_dit", "not_found")).to eq "not_found"
    end
  end

  describe "when environment is prod" do
    let(:manifest) { manifest_for_env("prod") }

    it "adds additional security groups" do
      expect(properties.fetch("cc.security_group_definitions.vpc_peer_dit")).to eq(
        "name" => "vpc_peer_dit",
        "rules" => [{
            "protocol" => "all",
            "destination" => "172.16.1.0/24",
        }]
      )
    end
  end
end
