require "json"

RSpec.describe "grafana dashboards" do
  grafana_dashboards.each do |dashboard_name, dashboard_contents|
    it "should end in .json" do
      expect(dashboard_name).to match(/[.]json$/)
    end

    it "should be valid json" do
      expect { JSON.parse dashboard_contents }.to_not raise_error
    end

    it "should be overwritable" do
      dashboard = JSON.parse(dashboard_contents)

      overwrite = dashboard.dig("overwrite")

      expect(overwrite).to eq(true)
    end

    it "should have folderId 0" do
      dashboard = JSON.parse(dashboard_contents)

      folder_id = dashboard.dig("folderId")

      expect(folder_id).to eq(0)
    end

    it "should have a title and uid" do
      dashboard = JSON.parse(dashboard_contents)

      title = dashboard.dig("dashboard", "title")
      uid = dashboard.dig("dashboard", "uid")

      expect(title).to be_kind_of(String)
      expect(uid).to be_kind_of(String)

      expect(title).to match(/[-A-Za-z0-9]+/)
      expect(uid).to match(/^[-a-z0-9]+$/)
    end
  end
end
