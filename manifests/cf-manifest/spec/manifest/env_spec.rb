
RSpec.describe "Environment specific configuration" do
  let(:default_manifest) { manifest_with_defaults }
  let(:prod_manifest) { load_default_manifest("prod") }

  def get_job_instances(manifest, job_name)
    manifest["jobs"].select { |j| j["name"] == job_name }.first["instances"]
  end

  it "should allow a higher number of instances of cells in production" do
    default_cell_instances = get_job_instances(default_manifest, "cell")
    prod_cell_instances = get_job_instances(prod_manifest, "cell")

    expect(default_cell_instances).to be < prod_cell_instances
  end
end
