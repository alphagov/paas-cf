RSpec.describe "networks" do
  let(:networks) { cloud_config_with_defaults.fetch("networks") }

  %w[cf cell router].each do |net_name|
    describe "#{net_name} network" do
      let(:network) { networks.find { |n| n["name"] == net_name } }

      it "has at least two subnets" do
        expect(network["subnets"].length).to be >= 2
      end

      it "sets the correct subnet ID" do
        network["subnets"].length.times do |i|
          subnet_fixture_key = "#{net_name}#{i + 1}_subnet_id"
          expect(network["subnets"][i]["cloud_properties"]["subnet"]).to eq(terraform_fixture_value(subnet_fixture_key))
        end
      end
    end
  end
end
