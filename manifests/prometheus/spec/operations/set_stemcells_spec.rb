RSpec.describe "pins a stemcell version" do
  specify "the version is not set to latest" do\
    stemcells = manifest_with_defaults.fetch("stemcells")
    default = stemcells.find { |s| s["alias"] == "default" }
    expect(default.fetch("version")).not_to eq("latest")
  end
end
