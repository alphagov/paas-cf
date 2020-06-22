RSpec.describe "update-networks.yml" do
  it "all instance_groups use the 'cf' network" do
    manifest_with_defaults.fetch("instance_groups").each do |ig|
      expect(ig.fetch("networks")).to eq([{ "name" => "cf" }])
    end
  end
end
