RSpec.describe "dev environment scaling" do
  after :each do
    ENV.delete("SLIM_DEV_DEPLOYMENT")
  end

  it "scales back dev environment when requested" do
    ENV["SLIM_DEV_DEPLOYMENT"] = "true"
    dev_manifest = manifest_for_dev

    # It scales back CF components to two instances
    expect(dev_manifest.fetch("instance_groups.api.instances")).to eq(2)
    expect(dev_manifest.fetch("instance_groups.doppler.instances")).to eq(2)
    expect(dev_manifest.fetch("instance_groups.diego-cell.instances")).to eq(2)

    # It scales back brokers to 1
    expect(dev_manifest.fetch("instance_groups.rds_broker.instances")).to eq(1)
    expect(dev_manifest.fetch("instance_groups.s3_broker.instances")).to eq(1)

    # It scales back cf-prometheus to 1
    expect(dev_manifest.fetch("instance_groups.prometheus.instances")).to eq(1)
    expect(dev_manifest.fetch("instance_groups.prometheus.vm_type")).to eq("small")
    expect(dev_manifest.fetch("instance_groups.prometheus.persistent_disk_type")).to eq("100GB")
    expect(dev_manifest.fetch("instance_groups.prometheus.jobs.prometheus2.properties.prometheus.storage.tsdb.retention.size")).to eq("90GB")
  end

  it "does not scale back dev otherwise" do
    dev_manifest = manifest_for_dev

    expect(dev_manifest.fetch("instance_groups.diego-cell.instances")).not_to eq(2)
    expect(dev_manifest.fetch("instance_groups.rds_broker.instances")).not_to eq(1)
    expect(dev_manifest.fetch("instance_groups.s3_broker.instances")).not_to eq(1)

    expect(dev_manifest.fetch("instance_groups.prometheus.vm_type")).to eq("xlarge")
    expect(dev_manifest.fetch("instance_groups.prometheus.persistent_disk_type")).to eq("500GB")
    expect(dev_manifest.fetch("instance_groups.prometheus.jobs.prometheus2.properties.prometheus.storage.tsdb.retention.size")).to eq("475GB")
  end
end
