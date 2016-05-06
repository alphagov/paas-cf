
RSpec.describe "Environment specific configuration" do

  let(:default_manifest) { load_default_manifest("default") }
  let(:prod_manifest) { load_default_manifest("prod") }

  def get_job_instances(manifest, job_name)
    manifest["jobs"].select{ |j| j["name"] == job_name}.first["instances"]
  end

  it "should allow a higher number of instances of cells in production" do

    default_cell_z1_instances = get_job_instances(default_manifest, "cell_z1")
    prod_cell_z1_instances = get_job_instances(prod_manifest, "cell_z1")

    expect(default_cell_z1_instances).to be < prod_cell_z1_instances
  end

end
