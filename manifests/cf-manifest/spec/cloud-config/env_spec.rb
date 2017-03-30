
RSpec.describe "Environment specific configuration" do
  let(:default_cloud_config) { cloud_config_with_defaults }
  let(:prod_cloud_config) { render_cloud_config("prod") }

  def get_disk_size(cloud_config, disk_name)
    cloud_config["disk_types"].select { |j| j["name"] == disk_name }.first["disk_size"]
  end

  it "should specify a larger elasticsearch disk size in production" do
    default_es_disk_size = get_disk_size(default_cloud_config, "elasticsearch_master")
    prod_es_disk_size = get_disk_size(prod_cloud_config, "elasticsearch_master")

    expect(default_es_disk_size).to be < prod_es_disk_size
  end
end
