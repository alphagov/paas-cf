RSpec.describe "compilation" do
  it "is not defined" do
    expect(cloud_config_with_defaults["compilation"]).to be_nil
  end
end
