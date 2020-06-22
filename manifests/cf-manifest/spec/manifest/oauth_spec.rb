RSpec.describe "OAuth" do
  let(:properties) { manifest.fetch("instance_groups.uaa.jobs.uaa.properties") }

  describe "by default" do
    let(:manifest) { manifest_with_defaults }

    it "enables the Google OAuth provider in UAA" do
      providers = properties.fetch("login").fetch("oauth").fetch("providers")
      expect(providers).to have_key "google"
    end

    it "enables the Microsoft OAuth provider in UAA" do
      providers = properties.fetch("login").fetch("oauth").fetch("providers")
      expect(providers).to have_key "microsoft"
    end

    it "enables a Google OAuth provider for administators in UAA" do
      providers = properties.fetch("login").fetch("oauth").fetch("providers")
      expect(providers).to have_key "admin-google"
    end

    it "ensures unique username attr mappings to ensure unique usernames" do
      providers = properties.fetch("login").fetch("oauth").fetch("providers")

      mappings = providers
        .values
        .map { |p| p.dig("attributeMappings", "user_name") }

      expect(mappings).to eq(mappings.uniq)
    end
  end
end
