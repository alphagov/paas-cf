
RSpec.describe "Environment specific configuration" do
  let(:default_manifest) { manifest_without_vars_store }
  let(:prod_manifest) { manifest_for_env("prod") }

  def get_instance_group_instances(manifest, instance_group_name)
    manifest["instance_groups"].select { |i| i["name"] == instance_group_name }.first["instances"]
  end

  it "allows a higher number of instances of cells in production" do
    default_cell_instances = get_instance_group_instances(default_manifest, "diego-cell")
    prod_cell_instances = get_instance_group_instances(prod_manifest, "diego-cell")

    expect(default_cell_instances).to be < prod_cell_instances
  end

  it "allows a higher number of instances of API servers in production" do
    default_api_instances = get_instance_group_instances(default_manifest, "api")
    prod_api_instances = get_instance_group_instances(prod_manifest, "api")

    expect(default_api_instances).to be < prod_api_instances
  end

  it "allows a higher number of instances of Doppler instances in production" do
    default_doppler_instances = get_instance_group_instances(default_manifest, "doppler")
    prod_doppler_instances = get_instance_group_instances(prod_manifest, "doppler")

    expect(default_doppler_instances).to be < prod_doppler_instances
  end

  %w[prod prod-lon stg-lon].each do |env|
    context "for the #{env} environment" do
      let(:env_manifest) { manifest_for_env(env) }

      it "has an equal number of cells per AZ" do
        cell_ig = env_manifest.fetch("instance_groups.diego-cell")
        az_count = cell_ig.fetch("azs").size
        expect(cell_ig.fetch("instances") % az_count).to eq(0),
          "cell instance count is not divisible by the AZ count"
      end
    end
  end
end
