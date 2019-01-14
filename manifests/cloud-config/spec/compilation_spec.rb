
RSpec.describe "compilation" do
  it "is defined" do
    expect(cloud_config_with_defaults["compilation"]).not_to be_empty
  end

  it "references an existing AZ" do
    az_list = cloud_config_with_defaults["azs"].map { |az| az["name"] }
    expect(az_list).to include(cloud_config_with_defaults["compilation"]["az"])
  end

  it "references an existing vm_type" do
    vm_type_list = cloud_config_with_defaults["vm_types"].map { |az| az["name"] }
    expect(vm_type_list).to include(cloud_config_with_defaults["compilation"]["vm_type"])
  end
end
