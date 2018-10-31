RSpec.describe "vm_extensions" do
  let(:manifest) { cloud_config_with_defaults }

  describe "prometheus_lb" do
    it "Should add the prometheus lb config" do
      expect(manifest['vm_extensions.prometheus_lb.cloud_properties.lb_target_groups']).to_not be_empty
    end
  end

  describe "bosh_client" do
    it "Should add the bosh_client security group" do
      expect(manifest['vm_extensions.bosh_client.cloud_properties.security_groups']).to_not be_empty
    end
  end
end
