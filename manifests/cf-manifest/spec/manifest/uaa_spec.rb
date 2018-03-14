RSpec.describe "uaa properties" do
  context "with the default certificates" do
    let(:manifest) { manifest_with_defaults }
    let(:properties) { manifest.fetch("instance_groups.uaa.jobs.uaa.properties") }

    it "has the same certificate for jwt policy signing keys" do
      jwt_keys = properties.fetch("uaa").fetch("jwt").fetch("policy").fetch("keys")
      expect(jwt_keys.keys.count).to eq(1)
      default_key = jwt_keys.fetch("544a04a5d328f8ff03a98768bf432f4650f654ea")
      expect(default_key.fetch("signingKey")).not_to be_empty
    end
  end
  context "with and old certificate for jwt signing" do
    let(:manifest) {
      manifest_with_custom_vars_file %{---
certs_uaa_jwt_signing_old_key: |
  -----BEGIN RSA PRIVATE KEY-----
  STUB_UAA_JWT_SIGNING_KEY_111111111111111111111111111111111111111
  1111111111111111111111111111111111111111111111111111111111111111
  1111111111111111111111111111111111111111111111111111111111111111
  1111111111111111111111111111111111111111111111111111111111111111
  1111111111111111111111111111111111111111111111111111111111111111
  -----END RSA PRIVATE KEY-----
certs_uaa_jwt_signing_old_key_hash: 0b3b65a62f37f9deb947f01602ae0a122bf91d7a
}
    }
    let(:properties) { manifest.fetch("instance_groups.uaa.jobs.uaa.properties") }

    it "has a different certificate for jwt policy signing keys" do
      jwt_keys = properties.fetch("uaa").fetch("jwt").fetch("policy").fetch("keys")
      expect(jwt_keys.keys.count).to eq(2)
      default_key = jwt_keys.fetch("544a04a5d328f8ff03a98768bf432f4650f654ea")
      previous_key = jwt_keys.fetch("0b3b65a62f37f9deb947f01602ae0a122bf91d7a")
      expect(default_key.fetch("signingKey")).not_to be_empty
      expect(default_key).not_to eq(previous_key)
    end
  end
end
