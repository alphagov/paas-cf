RSpec.describe "Monitor bosh" do
  it "adds the bosh_exporter job" do
    expect(manifest_with_defaults.get("instance_groups.prometheus2.jobs.bosh_exporter")).not_to be_nil
  end

  it "adds the bosh_alerts job" do
    expect(manifest_with_defaults.get("instance_groups.prometheus2.jobs.bosh_alerts")).not_to be_nil
  end

  it "adds the bosh_dashboards job" do
    expect(manifest_with_defaults.get("instance_groups.grafana.jobs.bosh_dashboards")).not_to be_nil
  end
end
