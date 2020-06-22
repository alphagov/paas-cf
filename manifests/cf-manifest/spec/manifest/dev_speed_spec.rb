RSpec.describe "dev deployment speed up" do
  after do
    ENV.delete("SLIM_DEV_DEPLOYMENT")
  end

  it "sets up instance groups across AZs in parallel" do
    expect {
      manifest_with_defaults.fetch("update.initial_deploy_az_update_strategy")
    }.to raise_error(KeyError)

    ENV["SLIM_DEV_DEPLOYMENT"] = "true"
    dev_manifest = manifest_for_dev

    expect(
      dev_manifest.fetch("update.initial_deploy_az_update_strategy"),
    ).to eq("parallel")
  end

  it "sets the vm strategy to create-swap-delete" do
    expect {
      manifest_with_defaults.fetch("update.vm_strategy")
    }.to raise_error(KeyError)

    ENV["SLIM_DEV_DEPLOYMENT"] = "true"
    dev_manifest = manifest_for_dev

    expect(
      dev_manifest.fetch("update.vm_strategy"),
    ).to eq("create-swap-delete")
  end
end
