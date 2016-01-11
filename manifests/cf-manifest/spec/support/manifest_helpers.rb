require 'open3'
require 'yaml'

module ManifestHelpers
  def manifest_with_defaults
    @@manifest_with_defaults ||= load_default_manifest
  end


  def terraform_fixture(key)
    @@fixture ||= load_terraform_fixture.fetch('terraform_outputs')
    @@fixture.fetch(key.to_s)
  end

  private

  def load_default_manifest
    output, error, status = Open3.capture3(
      {
        "TERRAFORM_OUTPUTS" => File.expand_path("../../fixtures/terraform-outputs.yml", __FILE__),
        "SECRETS"           => File.expand_path("../../fixtures/cf-secrets.yml", __FILE__),
        "SSL_CERTS"         => File.expand_path("../../fixtures/cf-ssl-certificates.yml", __FILE__),
      },
      File.expand_path("../../../build_manifest.sh", __FILE__),
    )
    expect(status).to be_success, "build_manifest.sh exited #{status.exitstatus}, stderr:\n#{error}"

    # Deep freeze the object so that it's safe to use across multiple examples
    # without risk of state leaking.
    deep_freeze(YAML.load(output))
  end

  def load_terraform_fixture
    data = YAML.load_file(File.expand_path("../../fixtures/terraform-outputs.yml", __FILE__))
    deep_freeze(data)
  end

  def deep_freeze(object)
    case object
    when Hash
      object.each { |k,v| deep_freeze(v) }
    when Array
      object.each { |v| deep_freeze(v) }
    end
    object.freeze
  end
end

RSpec.configuration.include ManifestHelpers
