
RSpec.describe "Environment specific configuration" do
  let(:default_manifest) { manifest_with_defaults }
  let(:prod_manifest) { render_manifest("prod") }

  def get_instance_group_instances(manifest, instance_group_name)
    manifest["instance_groups"].select { |i| i["name"] == instance_group_name }.first["instances"]
  end

  it "should allow a higher number of instances of cells in production" do
    default_cell_instances = get_instance_group_instances(default_manifest, "cell")
    prod_cell_instances = get_instance_group_instances(prod_manifest, "cell")

    expect(default_cell_instances).to be < prod_cell_instances
  end
end
