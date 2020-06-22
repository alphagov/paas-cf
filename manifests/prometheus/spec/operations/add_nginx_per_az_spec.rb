
RSpec.describe "adding VMs to the load balancer" do
  it "adds two nginx instance groups to separate azs" do
    expect(manifest_with_defaults.get("instance_groups.nginx_z1")).not_to be_empty
    expect(manifest_with_defaults.get("instance_groups.nginx_z1.name")).to eq("nginx_z1")
    expect(manifest_with_defaults.get("instance_groups.nginx_z1.azs")).to eq(["z1"])

    expect(manifest_with_defaults.get("instance_groups.nginx_z2")).not_to be_empty
    expect(manifest_with_defaults.get("instance_groups.nginx_z2.name")).to eq("nginx_z2")
    expect(manifest_with_defaults.get("instance_groups.nginx_z2.azs")).to eq(["z2"])
  end

  it "sets the same jobs and properties for both instance groups" do
    expect(manifest_with_defaults.get("instance_groups.nginx_z1.jobs").length).to eq(1)
    expect(manifest_with_defaults.get("instance_groups.nginx_z1.jobs.0.name")).to eq("nginx")
    expect(manifest_with_defaults.get("instance_groups.nginx_z1.jobs.0.release")).to eq("prometheus")


    expect(manifest_with_defaults.get("instance_groups.nginx_z2.jobs").length).to eq(1)
    expect(manifest_with_defaults.get("instance_groups.nginx_z2.jobs.0.name")).to eq("nginx")
    expect(manifest_with_defaults.get("instance_groups.nginx_z2.jobs.0.release")).to eq("prometheus")

    z1_nginx_props = manifest_with_defaults.get("instance_groups.nginx_z1.jobs.0.properties")
    expect(manifest_with_defaults.get("instance_groups.nginx_z2.jobs.0.properties")).to eq(z1_nginx_props)
  end

  it "disables the nginx bosh link on the second instance group" do
    expect(manifest_with_defaults.get("instance_groups.nginx_z2.jobs.0.provider.nginx")).to be_nil
  end

  it "sets the az-specific prometheus_lb vm_extension to the nginx VMs" do
    expect(manifest_with_defaults.get("instance_groups.nginx_z1.vm_extensions")).to eq(["prometheus_lb_z1"])
    expect(manifest_with_defaults.get("instance_groups.nginx_z2.vm_extensions")).to eq(["prometheus_lb_z2"])
  end
end
