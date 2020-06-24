RSpec.describe "S3 broker properties" do
  let(:manifest) { manifest_with_defaults }
  let(:properties) { manifest.fetch("instance_groups.s3_broker.jobs.s3-broker.properties.s3-broker") }

  describe "service plans" do
    let(:services) do
      properties.fetch("catalog").fetch("services")
    end
    let(:all_plans) do
      services.flat_map { |s| s["plans"] }
    end

    specify "all services have a unique id" do
      all_ids = services.map { |s| s["id"] }
      duplicated_ids = all_ids.select { |id| all_ids.count(id) > 1 }.uniq
      expect(duplicated_ids).to be_empty,
        "found duplicate service ids (#{duplicated_ids.join(',')})"
    end

    specify "all services have a unique name" do
      all_names = services.map { |s| s["name"] }
      duplicated_names = all_names.select { |name| all_names.count(name) > 1 }.uniq
      expect(duplicated_names).to be_empty,
        "found duplicate service names (#{duplicated_names.join(',')})"
    end

    specify "all plans have a unique id" do
      all_ids = all_plans.map { |p| p["id"] }
      duplicated_ids = all_ids.select { |id| all_ids.count(id) > 1 }.uniq
      expect(duplicated_ids).to be_empty,
        "found duplicate plan ids (#{duplicated_ids.join(',')})"
    end

    specify "all plans within each service have a unique name" do
      services.each do |s|
        all_names = s["plans"].map { |p| p["name"] }
        duplicated_names = all_names.select { |name| all_names.count(name) > 1 }.uniq
        expect(duplicated_names).to be_empty,
          "found duplicate plan names (#{duplicated_names.join(',')})"
      end
    end
  end

  describe "service broker is set to be shareable" do
    let(:services) do
      properties.fetch("catalog").fetch("services")
    end

    it "each service of the aws s3 service broker is shareable" do
      services.each do |service|
        service_name = service["name"]
        shareable = service.dig("metadata", "shareable")

        expect(shareable).not_to be(nil), "Service '#{service_name}' has to be shareable, but the 'shareable' parameter is missing in catalog/services/metadata"
        expect(shareable).to be(true), "Service '#{service_name}' has to be shareable, but the value of the parameter is #{shareable}"
      end
    end
  end
end
