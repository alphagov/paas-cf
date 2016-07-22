
RSpec.describe "Concourse collectd properties" do
  let(:manifest) { manifest_with_defaults }

  it "pulls from a shared config file" do
    concourse_job = manifest.fetch("jobs").find { |job| job["name"] == "concourse" }
    expect(concourse_job.fetch("properties").fetch("collectd").fetch("interval")).to eq 10
  end
end
