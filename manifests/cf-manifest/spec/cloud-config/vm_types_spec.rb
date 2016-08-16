
RSpec.describe "vm_types" do
  let(:vm_types) { manifest_with_defaults.fetch("vm_types") }

  describe "the router pool" do
    let(:pool) { vm_types.find { |p| p["name"] == "router" } }

    it "should use the correct elb instance" do
      expect(pool["cloud_properties"]["elbs"]).to match_array([
        terraform_fixture(:cf_router_elb_name),
      ])
    end
  end
end
