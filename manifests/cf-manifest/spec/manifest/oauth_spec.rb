RSpec.describe "Google OAuth" do
  let(:properties) { manifest.fetch("instance_groups.uaa.jobs.uaa.properties") }

  describe "by default" do
    let(:manifest) { manifest_with_defaults }
    it "enables the Google OAuth provider in UAA" do
      providers = properties.fetch("login").fetch("oauth").fetch("providers")
      expect(providers).to have_key 'google'
    end
  end
end
