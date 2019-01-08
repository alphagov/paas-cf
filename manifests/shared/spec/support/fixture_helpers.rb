module FixtureHelpers
  def terraform_fixture_value(key, fixture = 'cf')
    YAML.load_file(fixtures_dir.join("terraform/#{fixture}.yml")).fetch("terraform_outputs_#{key}")
  end

  def copy_terraform_fixtures(target_dir, fixtures = %w(vpc bosh concourse cf))
    fixtures.each do |file|
      copy_fixture_file("terraform/#{file}.yml", target_dir, "#{file}.yml")
    end
  end

  def copy_ipsec_cert_fixtures(target_dir)
    copy_fixture_file('ipsec-CA.crt', target_dir)
    copy_fixture_file('ipsec-CA.key', target_dir)
  end

  def copy_fixture_file(file, target_dir, target_file = file)
    FileUtils.mkdir(target_dir) unless Dir.exist?(target_dir)
    FileUtils.cp(fixtures_dir.join(file), "#{target_dir}/#{target_file}")
  end

  def generate_cf_secrets_fixture(target_dir)
    FileUtils.mkdir(target_dir) unless Dir.exist?(target_dir)
    File.open("#{target_dir}/cf-secrets.yml", 'w') do |file|
      output, error, status = Open3.capture3(File.expand_path("../../../cf-manifest/scripts/generate-cf-secrets.rb", __dir__))
      unless status.success?
        raise "Error generating cf-secrets, exit: #{status.exitstatus}, output:\n#{output}\n#{error}"
      end
      file.write(output)
    end
  end

private

  def fixtures_dir
    Pathname.new(File.expand_path('../fixtures', __dir__))
  end
end

RSpec.configuration.include FixtureHelpers
