RSpec.describe "Monitor CF" do
  it "adds the firehose instance_group" do
    firehose = manifest_with_defaults.get("instance_groups.prometheus2")
    expect(firehose).not_to be_nil
    expect(firehose["vm_type"]).to eq("medium")
    expect(firehose["networks"]).to eq([{ "name" => "cf" }])
  end

  it "adds the cf_exporter job" do
    cf_exporter_config = manifest_with_defaults.get(
      "instance_groups.prometheus2.jobs.cf_exporter",
    )

    expect(cf_exporter_config).not_to be_nil
  end

  it "adds the cloudfoundry_dashboards job" do
    cf_dashboards_config = manifest_with_defaults.get(
      "instance_groups.grafana.jobs.cloudfoundry_dashboards",
    )

    expect(cf_dashboards_config).not_to be_nil
  end
end
