module FixtureHelpers
  def terraform_fixture_value(key, fixture = "cf")
    YAML.load_file(fixtures_dir.join("terraform/#{fixture}.yml"), aliases: true).fetch("terraform_outputs_#{key}")
  end

  def copy_terraform_fixtures(target_dir, fixtures = %w[vpc bosh cf])
    fixtures.each do |file|
      copy_fixture_file("terraform/#{file}.yml", target_dir, "#{file}.yml")
    end
  end

  def copy_fixture_file(file, target_dir, target_file = file)
    FileUtils.mkdir(target_dir) unless Dir.exist?(target_dir)
    FileUtils.cp(fixtures_dir.join(file), "#{target_dir}/#{target_file}")
  end

private

  def fixtures_dir
    Pathname.new(File.expand_path("../fixtures", __dir__))
  end
end

RSpec.configuration.include FixtureHelpers
