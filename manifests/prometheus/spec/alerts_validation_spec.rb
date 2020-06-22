require "open3"

RSpec.describe "prometheus alerts" do
  prom_alerts = nil
  rules_file_location = "spec/alerts/fixtures/rules.yml"

  before do
    prom_alerts = YAML.dump(
      "groups" =>
        manifest_with_defaults["instance_groups"]
          .select { |ig| ig["name"] == "prometheus2" }
          .first["jobs"]
          .select { |j| j["name"] == "prometheus2" }
          .first.dig("properties", "prometheus", "custom_rules"),
    )

    File.write(rules_file_location, prom_alerts)
  end

  Dir.glob("*.test.yml", base: "spec/alerts/") do |filename|
    it "runs #{filename}" do
      _, err, status = Open3.capture3("promtool test rules spec/alerts/#{filename}")
      expect(status.success?).to be(true), "`promtool test rules #{filename}` should pass. #{err}"
    end
  end
end
