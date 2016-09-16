RSpec.describe "Runtime config" do
  let(:runtime_config) { load_runtime_config }

  it "the metron_agent is configured as a addon" do
    metron_agent_addon = runtime_config.fetch("addons").find { |addon| addon["name"] == "metron_agent" }

    expect(metron_agent_addon).not_to be_nil
    metron_agent_job = metron_agent_addon.fetch("jobs").find { |job| job["name"] == "metron_agent" }
    expect(metron_agent_job).not_to be_nil
  end
end
