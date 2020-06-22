require "ipaddr"

RSpec.describe "generic manifest validations" do
  let(:manifest) { manifest_with_defaults }
  let(:cloud_config) { cloud_config_with_defaults }

  specify "it must have a name" do
    expect(manifest["name"]).to match(/\S+/)
  end

  it "sets stemcell versions as strings" do
    manifest.fetch("stemcells").each do |stemcell|
      expect(stemcell.fetch("version")).to be_a(String)
    end
  end

  describe "name uniqueness" do
    %w[
      instance_groups
      releases
    ].each do |resource_type|
      specify "all #{resource_type} have a unique name" do
        all_resource_names = manifest.fetch(resource_type).map { |r| r["name"] }

        duplicated_names = all_resource_names.select { |n| all_resource_names.count(n) > 1 }.uniq
        expect(duplicated_names).to be_empty,
          "found duplicate names (#{duplicated_names.join(',')}) for #{resource_type}"
      end
    end
  end

  specify "all instance_groups have a bosh password set" do
    missing = []
    manifest.fetch("instance_groups").each do |ig|
      pw = ig.dig("env", "bosh", "password")
      missing << ig["name"] if pw.nil? || pw.empty?
    end
    expect(missing).to be_empty,
      "Expected instance_groups #{missing.inspect} to have env.bosh.password set"
  end

  describe "jobs cross-references" do
    specify "all jobs reference vm_types that exist" do
      vm_type_names = cloud_config["vm_types"].map { |r| r["name"] }
      manifest["instance_groups"].each do |job|
        expect(vm_type_names).to include(job["vm_type"]),
          "vm_type #{job['vm_type']} not found for job #{job['name']}"
      end
    end

    specify "all jobs reference vm_extensions that exist" do
      vm_extension_names = cloud_config.fetch("vm_extensions", []).map { |r| r["name"] }
      manifest["instance_groups"].each do |job|
        job.fetch("vm_extensions", []).each do |extension|
          expect(vm_extension_names).to include(extension),
            "vm_extension '#{extension}' not found for job #{job['name']}"
        end
      end
    end

    specify "all jobs reference stemcells that exist" do
      stemcell_names = manifest["stemcells"].map { |r| r["alias"] }
      manifest["instance_groups"].each do |job|
        expect(job.has_key?("stemcell")).to be(true),
          "No stemcell defined for job #{job['name']}. You must add a stemcell to this job."
        expect(stemcell_names).to include(job["stemcell"]),
          "stemcell #{job['stemcell']} not found for job #{job['name']}. This value should correspond to `stemcells.*.alias`."
      end
    end

    specify "all jobs reference availability zones that exist" do
      azs_names = cloud_config["azs"].map { |r| r["name"] }
      manifest["instance_groups"].each do |job|
        expect(job.has_key?("azs")).to be(true),
          "No azs key defined for job #{job['name']}. You must add some availability zones."
        job["azs"].each do |az|
          expect(azs_names).to include(az),
            "AZ #{az} not found for job #{job['name']}. Check this az exists in the Cloud Config."
        end
      end
    end

    specify "all vm jobs reference releases that exist" do
      release_names = manifest["releases"].map { |r| r["name"] }

      manifest["instance_groups"].each do |instance_group|
        instance_group["jobs"].each do |job|
          expect(release_names).to include(job["release"]),
            "release #{job['release']} not found for job #{job['name']} in instance_group #{instance_group['name']}"
        end
      end
    end

    describe "networks" do
      let(:networks_by_name) do
        cloud_config["networks"].each_with_object({}) { |net, result| result[net["name"]] = net }
      end
      let(:network_names) { networks_by_name.keys }

      specify "all jobs reference networks that exist" do
        manifest["instance_groups"].each do |job|
          job["networks"].each do |network|
            expect(network_names).to include(network["name"]),
              "network #{network['name']} not found for job #{job['name']}"
          end
        end
      end
    end

    specify "all jobs reference disk_types that exist" do
      disk_type_names = cloud_config.fetch("disk_types", {}).map { |p| p["name"] }

      manifest["instance_groups"].each do |job|
        next unless job["persistent_disk_type"]

        expect(disk_type_names).to include(job["persistent_disk_type"]),
          "disk_type #{job['persistent_disk_type']} not found for job #{job['name']}"
      end
    end
  end
end
