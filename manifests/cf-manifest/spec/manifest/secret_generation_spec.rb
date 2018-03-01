require 'tempfile'

RSpec.describe "secret generation" do
  describe "generate-cf-secrets" do
    specify "it should produce lint-free YAML" do
      output, status = Open3.capture2e('yamllint', '-c', File.expand_path("../../../../../yamllint.yml", __FILE__), cf_secrets_file)

      expect(status).to be_success, "yamllint exited #{status.exitstatus}, output:\n#{output}"
      expect(output).to be_empty
    end

    specify "it should be able to update and old secrets file" do
      Tempfile.open(['original-cf-secrets', '.yml']) { |file|
        file.write(%{
---
secrets:
  bbs_encryption_key: ___previous_bbs_encryption_key___
  bulk_api_password: ___previous_bulk_api_password___
  cc_db_encryption_key: ___previous_cc_db_encryption_key___
  ssh_proxy_host_key:
    private_key: |
      aaaaaaaaaaa
      bbbbbbbbbbb
    public_fingerprint: f4:cc:45:d3:bb:33:ca:94:6a:51:7a:1c:fe:06:b7:a6
})
        file.flush
        file.close

        output, error, status = Open3.capture3(
          root.join("manifests/cf-manifest/scripts/generate-cf-secrets.rb").to_s,
          "--existing-secrets",
          file.path.to_s
        )
        unless status.success?
          raise "Error updating cf-secrets #{file.path}, exit: #{status.exitstatus}, output:\n#{output}\n#{error}"
        end

        resulting_secrets = YAML.safe_load(output)
        expect(resulting_secrets["secrets"]).to be_nil
        expect(resulting_secrets["secrets_bbs_encryption_key"]).to eq("___previous_bbs_encryption_key___")
        expect(resulting_secrets["secrets_bulk_api_password"]).to eq("___previous_bulk_api_password___")
        expect(resulting_secrets["secrets_cc_db_encryption_key"]).to eq("___previous_cc_db_encryption_key___")
        expect(resulting_secrets["secrets_ssh_proxy_host_key"]).to eq("private_key" => "aaaaaaaaaaa\nbbbbbbbbbbb\n",
          "public_fingerprint" => "f4:cc:45:d3:bb:33:ca:94:6a:51:7a:1c:fe:06:b7:a6")
      }
    end
  end
end
