REPO_ROOT = File.expand_path(File.join(SPEC_DIR, "..", ".."))

RSpec.describe "vars files" do
  it "gpg-keys.yml was updated after a change to .gpg-id" do
    gpg_id_mod_time = File.mtime(File.join(REPO_ROOT, ".gpg-id"))
    gpg_keys_mod_time = File.mtime(File.join(REPO_ROOT, "concourse", "vars-files", "gpg-keys.yml"))

    expect(gpg_keys_mod_time).to be >= gpg_id_mod_time
  end
end
