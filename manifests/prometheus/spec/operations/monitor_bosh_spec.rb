RSpec.describe "Monitor bosh" do
  it "adds the bosh_exporter job" do
    expect(manifest_with_defaults.get("instance_groups.prometheus2.jobs.bosh_exporter")).to_not be_nil
  end
  it "adds the bosh_alerts job" do
    expect(manifest_with_defaults.get("instance_groups.prometheus2.jobs.bosh_alerts")).to_not be_nil
  end
  it "adds the bosh_dashboards job" do
    expect(manifest_with_defaults.get("instance_groups.grafana.jobs.bosh_dashboards")).to_not be_nil
  end
end
