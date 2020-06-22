RSpec.describe "update-vm-types.yml" do
  {
    "alertmanager" => "nano",
    "grafana" => "nano",
    "prometheus2" => "medium",
  }.each do |name, type|
    it "sets the vm_type for #{name} to #{type}" do
      expect(manifest_with_defaults.get("instance_groups.#{name}.vm_type")).to eq(type)
    end
  end
end
