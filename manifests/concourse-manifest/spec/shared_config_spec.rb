
RSpec.describe "Concourse shared properties" do
  let(:manifest) { manifest_with_defaults }
  let(:concourse_job) { manifest.fetch("jobs").find { |job| job["name"] == "concourse" } }
  let(:collectd_template) { concourse_job.fetch("templates").find { |t| t["name"] == "collectd" } }
  let(:datadog_template) { concourse_job.fetch("templates").find { |t| t["name"] == "datadog-agent" } }

  it "pulls collectd properties from a shared config file" do
    expect(collectd_template.fetch("properties").fetch("collectd").fetch("interval")).to eq(10)
  end

  it "Adds datadog and pulls datadog properties from a shared config file" do
    expect(datadog_template.fetch("properties").fetch("use_dogstatsd")).to eq(false)
  end
end
