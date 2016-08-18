
RSpec.describe "compilation" do
  let(:manifest) { manifest_with_defaults }

  it "is defined" do
    expect(manifest["compilation"]).not_to be_empty
  end

  it "references an existing AZ" do
    az_list = manifest["azs"].map { |az| az["name"] }
    expect(az_list).to include(manifest["compilation"]["az"])
  end

  it "references an existing vm_type" do
    vm_type_list = manifest["vm_types"].map { |az| az["name"] }
    expect(vm_type_list).to include(manifest["compilation"]["vm_type"])
  end
end
