require 'tempfile'

RSpec.describe "secret generation" do
  describe "generate-cf-secrets" do
    specify "it should produce lint-free YAML" do
      dir = Dir.mktmpdir('paas-cf-test')
      begin
        generate_cf_secrets_fixture(dir)

        output, status = Open3.capture2e('yamllint', '-c', File.expand_path("../../../../../yamllint.yml", __FILE__), "#{dir}/cf-secrets.yml")

        expect(status).to be_success, "yamllint exited #{status.exitstatus}, output:\n#{output}"
        expect(output).to be_empty
      ensure
        FileUtils.rm_rf(dir)
      end
    end
  end
end
