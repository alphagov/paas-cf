require 'tempfile'

RSpec.describe "secret generation" do
  describe "generate-cf-secrets" do
    specify "it should produce lint-free YAML" do
      output, status = Open3.capture2e('yamllint', '-c', File.expand_path("../../../../../yamllint.yml", __FILE__), cf_secrets_file)

      expect(status).to be_success, "yamllint exited #{status.exitstatus}, output:\n#{output}"
      expect(output).to be_empty
    end
  end
end
