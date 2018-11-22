
RSpec.describe "Environment specific configuration" do
  let(:default_manifest) { manifest_without_vars_store }
  let(:prod_manifest) { manifest_for_prod }

  def get_instance_group_instances(manifest, instance_group_name)
    manifest["instance_groups"].select { |i| i["name"] == instance_group_name }.first["instances"]
  end

  it "should allow a higher number of instances of cells in production" do
    default_cell_instances = get_instance_group_instances(default_manifest, "diego-cell")
    prod_cell_instances = get_instance_group_instances(prod_manifest, "diego-cell")

    expect(default_cell_instances).to be < prod_cell_instances
  end

  it "should allow a higher number of instances of API servers in production" do
    default_api_instances = get_instance_group_instances(default_manifest, "api")
    prod_api_instances = get_instance_group_instances(prod_manifest, "api")

    expect(default_api_instances).to be < prod_api_instances
  end
end
