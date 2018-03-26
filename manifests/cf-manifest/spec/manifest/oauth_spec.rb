RSpec.describe "Google OAuth" do
  let(:properties) { manifest.fetch("instance_groups.uaa.jobs.uaa.properties") }

  describe "when user creation is not enabled" do
    let(:manifest) { manifest_with_defaults }
    it "enables the Google OAuth provider in UAA" do
      expect(properties.fetch('login')).to_not have_key 'oauth'
    end
  end

  describe "when user creation is enabled" do
    let(:manifest) { manifest_with_enable_user_creation }
    it "enables the Google OAuth provider in UAA" do
      providers = properties.fetch("login").fetch("oauth").fetch("providers")
      expect(providers).to have_key 'google'
    end
  end
end
