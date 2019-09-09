RSpec.describe "alertmanager" do
  it "should have a pagerduty receiver with a credhub provided service key" do
    pagerduty_configs = manifest_with_defaults.get("instance_groups.alertmanager.jobs.alertmanager.properties.alertmanager.receivers.pagerduty-receiver.pagerduty_configs")
    expect(pagerduty_configs[0]['service_key']).to eq("((alertmanager_pagerduty_service_key))")
  end
end
