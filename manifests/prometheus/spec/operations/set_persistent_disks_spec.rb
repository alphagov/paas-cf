RSpec.describe "setting persistent disks" do
  {
    "alertmanager" => "5GB",
    "grafana" => "5GB",
    "prometheus2" => "100GB",
  }.each do |name, type|
    it "sets the persistent_disk_type for #{name} to #{type}" do
      expect(manifest_with_defaults.get("instance_groups.#{name}.persistent_disk_type")).to eq(type)
    end
  end

  specify "none of the VMs specify a persistent_disk" do
    manifest_with_defaults.fetch("instance_groups").each do |ig|
      expect(ig).not_to have_key("persistent_disk")
    end
  end
end
