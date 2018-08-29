RSpec.describe "Grafana uses sqlite3 instead of database VM" do
  specify "there is no database VM" do
    expect(manifest_with_defaults.get("instance_groups.database")).to be_nil
  end

  specify "grafana is not configured with any database config" do
    grafana_props = manifest_with_defaults.get("instance_groups.grafana.jobs.grafana.properties.grafana")
    expect(grafana_props).not_to have_key("database")
    expect(grafana_props).not_to have_key("session")
  end

  specify "there is no postgres release" do
    expect(manifest_with_defaults.get("releases.postgres")).to be_nil
  end
end
