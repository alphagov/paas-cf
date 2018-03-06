
RSpec.describe "Environment specific configuration" do
  let(:default_cloud_config) { cloud_config_with_defaults }
  let(:prod_cloud_config) { render_cloud_config("prod") }

  def get_disk_size(cloud_config, disk_name)
    cloud_config["disk_types"].select { |j| j["name"] == disk_name }.first["disk_size"]
  end

  def get_instance_type(cloud_config, vm_type)
    cloud_config["vm_types"].find { |v| v["name"] == vm_type }["cloud_properties"]["instance_type"]
  end


  it "should specify a larger elasticsearch disk size in production" do
    default_es_disk_size = get_disk_size(default_cloud_config, "elasticsearch_master")
    prod_es_disk_size = get_disk_size(prod_cloud_config, "elasticsearch_master")

    expect(default_es_disk_size).to be < prod_es_disk_size
  end

  it "should specify a different parser VM size in production" do
    default_parser_vm = get_instance_type(default_cloud_config, "parser")
    prod_parser_vm = get_instance_type(prod_cloud_config, "parser")

    expect(prod_parser_vm).not_to eq(default_parser_vm)
  end
end
