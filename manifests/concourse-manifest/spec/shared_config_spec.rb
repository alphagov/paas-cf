
RSpec.describe "Concourse collectd properties" do
  let(:manifest) { manifest_with_defaults }
  let(:concourse_job) { manifest.fetch("jobs").find { |job| job["name"] == "concourse" } }
  let(:collectd_template) { concourse_job.fetch("templates").find { |t| t["name"] == "collectd" } }

  it "pulls from a shared config file" do
    expect(collectd_template.fetch("properties").fetch("collectd").fetch("interval")).to eq(10)
  end
end
