RSpec.describe "manifest properties validations" do
  let(:manifest) { manifest_with_defaults }
  let(:bosh_properties) { manifest.fetch("jobs").select { |x| x["name"] == "bosh" }.first["properties"] }

  it "configures hm bosh user with password" do
    users = bosh_properties["director"]["user_management"]["local"]["users"]
    hm = users.find { |u| u['name'] == 'hm' }
    expect(hm).to be
    expect(hm["password"]).to eq("BOSH_HM_DIRECTOR_PASSWORD")
  end

  it "configures admin bosh user with password" do
    users = bosh_properties["director"]["user_management"]["local"]["users"]
    admin = users.find { |u| u['name'] == 'admin' }
    expect(admin).to be
    expect(admin["password"]).to eq("BOSH_ADMIN_PASSWORD")
  end

  it "creates a local user for health manager" do
    users = bosh_properties["director"]["user_management"]["local"]["users"]
    expected_user = { "name" => "hm", "password" => "BOSH_HM_DIRECTOR_PASSWORD" }
    expect(users).to include(expected_user)
  end

  it "configures the hm bosh user as director account of the health manager" do
    expect(bosh_properties["hm"]["director_account"]["user"]).to eq("hm")
    expect(bosh_properties["hm"]["director_account"]["password"]).to eq("BOSH_HM_DIRECTOR_PASSWORD")
  end

  it "disables the health manager resurrector" do
    expect(bosh_properties["hm"]["resurrector_enabled"]).to eq(false)
  end
end
