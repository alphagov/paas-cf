RSpec.describe "uaa properties" do
  context "with the default certificates" do
    let(:manifest) { manifest_with_defaults }
    let(:properties) { manifest.fetch("instance_groups.uaa.jobs.uaa.properties") }

    it "has a certificate for jwt policy signing keys" do
      jwt_keys = properties.fetch("uaa").fetch("jwt").fetch("policy").fetch("keys")
      expect(jwt_keys.keys.count).to eq(2)
      jwt_active_key_id = properties.fetch("uaa").fetch("jwt").fetch("policy").fetch("active_key_id")
      default_key = jwt_keys.fetch(jwt_active_key_id)
      expect(default_key.fetch("signingKey")).not_to be_empty
    end
  end

  context "when setting the cf cli token validity" do
    let(:manifest) { manifest_with_defaults }
    let(:cf_client) { manifest.fetch("instance_groups.uaa.jobs.uaa.properties.uaa.clients.cf") }
    let(:refresh_token_validity) { cf_client.fetch("refresh-token-validity") }
    let(:access_token_validity) { cf_client.fetch("access-token-validity") }

    it "sets the refresh token validity to 20 hours" do
      expect(refresh_token_validity).to equal(72_000)
    end

    it "doesn't set the access token validity to higher than the refresh validity" do
      expect(access_token_validity).to be <= refresh_token_validity
    end
  end
end
