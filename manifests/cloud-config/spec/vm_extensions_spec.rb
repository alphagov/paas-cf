RSpec.describe "vm_extensions" do
  let(:manifest) { cloud_config_with_defaults }

  describe "prometheus" do
    it "adds the target group configs" do
      expect(manifest["vm_extensions.prometheus_lb_z1.cloud_properties.lb_target_groups"]).to_not be_empty
      expect(manifest["vm_extensions.prometheus_lb_z2.cloud_properties.lb_target_groups"]).to_not be_empty
    end
  end

  describe "bosh_client" do
    it "adds the bosh_client security group" do
      expect(manifest["vm_extensions.bosh_client.cloud_properties.security_groups"]).to_not be_empty
    end
  end
end
