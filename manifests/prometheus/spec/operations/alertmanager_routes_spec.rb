RSpec.describe "alertmanager" do
  it "should have a 24/7 pagerduty receiver with a credhub provided service key" do
    pagerduty_24_7_configs = manifest_with_defaults.get("instance_groups.alertmanager.jobs.alertmanager.properties.alertmanager.receivers.pagerduty-24-7-receiver.pagerduty_configs")
    expect(pagerduty_24_7_configs[0]['service_key']).to eq("((alertmanager_pagerduty_24_7_service_key))")
  end

  it "should have an in-hours pagerduty receiver with a credhub provided service key" do
    pagerduty_in_hours_configs = manifest_with_defaults.get("instance_groups.alertmanager.jobs.alertmanager.properties.alertmanager.receivers.pagerduty-in-hours-receiver.pagerduty_configs")
    expect(pagerduty_in_hours_configs[0]['service_key']).to eq("((alertmanager_pagerduty_in_hours_service_key))")
  end
end
