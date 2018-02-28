RSpec.describe "uaa properties" do
  context "with the default certificates" do
    let(:manifest) { manifest_with_defaults }
    let(:properties) { manifest.fetch("properties") }

    it "has the same certificate for jwt policy signing keys" do
      jwt_keys = properties.fetch("uaa").fetch("jwt").fetch("policy").fetch("keys")
      default_key = jwt_keys.fetch("default")
      previous_key = jwt_keys.fetch("previous")
      expect(default_key.fetch("signingKey")).not_to be_empty
      expect(default_key).to eq(previous_key)
    end
  end
  context "with and old certificate for jwt signing" do
    let(:manifest) {
      manifest_with_custom_vars_file  %{---
secrets:
  uaa_jwt_signing_old_key: |
    -----BEGIN RSA PRIVATE KEY-----
    STUB_UAA_JWT_SIGNING_KEY_111111111111111111111111111111111111111
    1111111111111111111111111111111111111111111111111111111111111111
    1111111111111111111111111111111111111111111111111111111111111111
    1111111111111111111111111111111111111111111111111111111111111111
    1111111111111111111111111111111111111111111111111111111111111111
    -----END RSA PRIVATE KEY-----}
    }
    let(:properties) { manifest.fetch("properties") }

    it "has a different certificate for jwt policy signing keys" do
      jwt_keys = properties.fetch("uaa").fetch("jwt").fetch("policy").fetch("keys")
      default_key = jwt_keys.fetch("default")
      previous_key = jwt_keys.fetch("previous")
      expect(default_key.fetch("signingKey")).not_to be_empty
      expect(default_key).not_to eq(previous_key)
    end
  end
end
