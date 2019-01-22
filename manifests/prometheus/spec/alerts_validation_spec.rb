require 'open3'

RSpec.describe "prometheus alerts" do

    prom_alerts = nil

    before(:all) do
        prom_alerts = YAML.dump({
            "groups" =>
                manifest_with_defaults["instance_groups"]
                    .select{|ig|ig["name"] == 'prometheus2'}
                    .first["jobs"]
                    .select{|j|j["name"]=='prometheus2'}
                    .first.dig("properties", "prometheus", "custom_rules")
        })
    end

    Dir.each_child('spec/alerts') do |filename|
        it "runs #{filename}" do
            out, err, status = Open3.capture3("promtool test rules spec/alerts/#{filename}", stdin_data: prom_alerts)
            expect(status.success?).to be(true), "`promtool test rules ...` should pass. #{err}"
        end
    end
end