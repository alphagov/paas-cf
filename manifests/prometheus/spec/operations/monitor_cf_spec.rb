RSpec.describe "Monitor CF" do
  it "adds the firehose instance_group" do
    firehose = manifest_with_defaults.get("instance_groups.prometheus2")
    expect(firehose).not_to be_nil
    expect(firehose["vm_type"]).to eq("medium_previous_generation")
    expect(firehose["networks"]).to eq([{ "name" => "cf" }])
  end

  it "does not add the cf_exporter job" do
    expect(manifest_with_defaults.get("instance_groups.prometheus2.jobs.cf_exporter")).to be_nil
  end

  it "adds the cloudfoundry_dashboards job" do
    expect(manifest_with_defaults.get("instance_groups.grafana.jobs.cloudfoundry_dashboards")).to_not be_nil
  end
end
