
RSpec.describe "adding VMs to the load balancer" do
  it "adds the prometheus_lb vm_extension to the nginx VM" do
    expect(manifest_with_defaults.get("instance_groups.nginx.vm_extensions")).to eq(["prometheus_lb"])
  end
end
