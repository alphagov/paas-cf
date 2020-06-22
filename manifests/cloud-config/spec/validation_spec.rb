
RSpec.describe "generic validations" do
  describe "name uniqueness" do
    %w[
      disk_types
      networks
      vm_types
    ].each do |resource_type|
      specify "all #{resource_type} have a unique name" do
        all_resource_names = cloud_config_with_defaults.fetch(resource_type).map { |r| r["name"] }

        duplicated_names = all_resource_names.select { |n| all_resource_names.count(n) > 1 }.uniq
        expect(duplicated_names).to be_empty,
          "found duplicate names (#{duplicated_names.join(',')}) for #{resource_type}"
      end
    end
  end
end
