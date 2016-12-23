
RSpec.describe "Environment specific configuration" do
  let(:default_manifest) { load_default_manifest("default") }
  let(:prod_manifest) { load_default_manifest("prod") }

  def get_job_instances(manifest, job_name)
    manifest["jobs"].select { |j| j["name"] == job_name }.first["instances"]
  end

  it "should allow a higher number of instances of cells in production" do
    default_cell_instances = get_job_instances(default_manifest, "cell")
    prod_cell_instances = get_job_instances(prod_manifest, "cell")

    expect(default_cell_instances).to be < prod_cell_instances
  end

  def get_disk_size(manifest, disk_name)
    manifest["disk_types"].select { |j| j["name"] == disk_name }.first["disk_size"]
  end

  it "should specify a larger elasticseach disk size in production" do
    default_es_disk_size = get_disk_size(default_manifest, "elasticsearch_master")
    prod_es_disk_size = get_disk_size(prod_manifest, "elasticsearch_master")

    expect(default_es_disk_size).to be < prod_es_disk_size
  end
end
