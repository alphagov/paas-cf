RSpec.describe "dev environment scaling" do
  after :each do
    ENV.delete('SLIM_DEV_DEPLOYMENT')
  end

  it "scales back dev environment when requested" do
    ENV['SLIM_DEV_DEPLOYMENT'] = "true"
    dev_manifest = manifest_for_dev

    # It scales back CF components
    expect(dev_manifest.fetch("instance_groups.api.instances")).to eq(1)
    expect(dev_manifest.fetch("instance_groups.doppler.instances")).to eq(1)

    # It scales back additional components
    expect(dev_manifest.fetch("instance_groups.rds_broker.instances")).to eq(1)
  end

  it "does not scale back dev otherwise" do
    dev_manifest = manifest_for_dev

    expect(dev_manifest.fetch("instance_groups.api.instances")).not_to eq(1)
    expect(dev_manifest.fetch("instance_groups.rds_broker.instances")).not_to eq(1)
  end
end
