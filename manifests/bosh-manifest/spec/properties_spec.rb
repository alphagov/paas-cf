RSpec.describe "manifest properties validations" do
  let(:manifest) { manifest_with_defaults }
  let(:properties) { manifest.fetch("properties") }
  let(:bosh_job) { manifest.fetch("jobs").select{|x| x["name"] == "bosh"}.first }
  let(:bosh_properties) { properties.merge(bosh_job["properties"]) }

  it "uses local user management" do
    expect(bosh_properties["director"]["user_management"]["provider"]).to eq("local")
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

  it "enables the health manager resurrector" do
    expect(bosh_properties["hm"]["resurrector_enabled"]).to eq(true)
  end
end
