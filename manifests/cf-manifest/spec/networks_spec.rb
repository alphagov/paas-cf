
RSpec.describe "networks" do
  CF_NETWORK_NAMES = %w(
    cf1
    cf2
  )

  let(:networks) { manifest_with_defaults.fetch("networks") }

  CF_NETWORK_NAMES.each do |net_name|
    describe "#{net_name} network" do
      let(:network) { networks.find {|n| n["name"] == net_name } }

      it "should have a single subnet" do
        expect(network["subnets"].length).to eq(1)
      end

      it "should set the correct subnet ID" do
        expect(network["subnets"].first["cloud_properties"]["subnet"]).to eq(terraform_fixture("#{net_name}_subnet_id"))
      end
    end
  end
end
