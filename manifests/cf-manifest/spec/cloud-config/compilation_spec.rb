
RSpec.describe "compilation" do
  it "is defined" do
    expect(cloud_config["compilation"]).not_to be_empty
  end

  it "references an existing AZ" do
    az_list = cloud_config["azs"].map { |az| az["name"] }
    expect(az_list).to include(cloud_config["compilation"]["az"])
  end

  it "references an existing vm_type" do
    vm_type_list = cloud_config["vm_types"].map { |az| az["name"] }
    expect(vm_type_list).to include(cloud_config["compilation"]["vm_type"])
  end
end
