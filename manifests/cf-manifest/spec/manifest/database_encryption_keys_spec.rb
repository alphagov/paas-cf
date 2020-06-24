RSpec.describe "database encryption keys" do
  let(:manifest) { manifest_without_vars_store }

  describe "CC database encryption key" do
    %w[
      instance_groups.api.jobs.cloud_controller_ng.properties
      instance_groups.cc-worker.jobs.cloud_controller_worker.properties
      instance_groups.scheduler.jobs.cloud_controller_clock.properties
    ].each do |job_properties_path|
      it "has a default encryption key configured" do
        properties = manifest.fetch(job_properties_path)

        current_key_label = properties.fetch("cc").fetch("database_encryption").fetch("current_key_label")
        keys = properties.fetch("cc").fetch("database_encryption").fetch("keys")

        expect(current_key_label).to eq("((cc_db_encryption_key_id))")
        expect(keys[current_key_label]).to eq("((cc_db_encryption_key))")
      end

      it "keeps the _old key as key" do
        properties = manifest.fetch(job_properties_path)

        keys = properties.fetch("cc").fetch("database_encryption").fetch("keys")

        expect(keys).to include("((cc_db_encryption_key_id))" => "((cc_db_encryption_key))")
        expect(keys).to include("((cc_db_encryption_key_id_old))" => "((cc_db_encryption_key_old))")
      end
    end

    it "only has ((cc_db_encryption_key)) in the expected locations" do
      found_locations = manifest.inject([]) do |acum, v, path|
        new_acum = acum
        new_acum << path if v.is_a?(String) && v.include?("((cc_db_encryption_key))")
        new_acum
      end
      expected_locations = %w[
        /instance_groups/name=api/jobs/name=cloud_controller_ng/properties/cc/database_encryption/keys/((cc_db_encryption_key_id))
        /instance_groups/name=api/jobs/name=cloud_controller_ng/properties/cc/db_encryption_key
        /instance_groups/name=cc-worker/jobs/name=cloud_controller_worker/properties/cc/database_encryption/keys/((cc_db_encryption_key_id))
        /instance_groups/name=cc-worker/jobs/name=cloud_controller_worker/properties/cc/db_encryption_key
        /instance_groups/name=scheduler/jobs/name=cloud_controller_clock/properties/cc/database_encryption/keys/((cc_db_encryption_key_id))
        /instance_groups/name=scheduler/jobs/name=cloud_controller_clock/properties/cc/db_encryption_key
        /instance_groups/name=scheduler/jobs/name=cc_deployment_updater/properties/cc/db_encryption_key
      ]
      expect(found_locations).to contain_exactly(*expected_locations)
    end
  end

  describe "UAA database encryption key" do
    it "has a default encryption key configured" do
      properties = manifest.fetch("instance_groups.uaa.jobs.uaa.properties")

      active_key_label = properties.fetch("encryption").fetch("active_key_label")
      keys = properties.fetch("encryption").fetch("encryption_keys")

      expect(active_key_label).to eq("((uaa_default_encryption_passphrase_id))")

      expect(keys).to include(
        "label" => "((uaa_default_encryption_passphrase_id))",
        "passphrase" => "((uaa_default_encryption_passphrase))",
      )
    end

    it "keeps the _old key as key" do
      properties = manifest.fetch("instance_groups.uaa.jobs.uaa.properties")

      keys = properties.fetch("encryption").fetch("encryption_keys")

      expect(keys).to include(
        "label" => "((uaa_default_encryption_passphrase_id))",
        "passphrase" => "((uaa_default_encryption_passphrase))",
      )
      expect(keys).to include(
        "label" => "((uaa_default_encryption_passphrase_id_old))",
        "passphrase" => "((uaa_default_encryption_passphrase_old))",
      )
    end
  end
end
