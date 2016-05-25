
RSpec.describe "resource_pools" do
  let(:resource_pools) { manifest_with_defaults.fetch("resource_pools") }

  POOL_BASE_NAMES = %w(
    small
    medium
    api
    router
  )
  ZONE_KEYS = {
    "z1" => :zone0,
    "z2" => :zone1,
  }

  POOL_BASE_NAMES.each do |base_name|
    ZONE_KEYS.keys.each do |zone_suffix|
      describe "#{base_name}_#{zone_suffix}" do
        let(:pool) { resource_pools.find {|p| p["name"] == "#{base_name}_#{zone_suffix}" } }

        it "should specify the correct AWS AZ" do
          expect(pool["cloud_properties"]["availability_zone"]).to eq(terraform_fixture(ZONE_KEYS[zone_suffix]))
        end
      end
    end
  end

  describe "the compilation pool" do
    let(:compilation) { manifest_with_defaults.fetch("compilation") }

    it "should specify the correct AWS AZ" do
      expect(compilation["cloud_properties"]["availability_zone"]).to eq(terraform_fixture(:zone0))
    end
  end

  describe "router pools" do
    ZONE_KEYS.keys.each do |zone_suffix|
      context "in zone #{zone_suffix}" do
        let(:pool) { resource_pools.find {|p| p["name"] == "router_#{zone_suffix}" } }

        it "should use the correct elb instance" do
          expect(pool["cloud_properties"]["elbs"]).to match_array([
            terraform_fixture(:cf_router_elb_name),
          ])
        end
      end
    end
  end
end
