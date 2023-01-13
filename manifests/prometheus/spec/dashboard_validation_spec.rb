require "json"

RSpec.describe "grafana dashboards" do
  grafana_dashboards.each do |dashboard_name, dashboard_contents|
    it "ends in .json" do
      expect(dashboard_name).to match(/[.]json$/)
    end

    it "is valid json" do
      expect { JSON.parse dashboard_contents }.not_to raise_error
    end

    it "is overwritable" do
      dashboard = JSON.parse(dashboard_contents)

      overwrite = dashboard["overwrite"]

      expect(overwrite).to eq(true)
    end

    it "has folderId 0" do
      dashboard = JSON.parse(dashboard_contents)

      folder_id = dashboard["folderId"]

      expect(folder_id).to eq(0)
    end

    it "has a title and uid" do
      dashboard = JSON.parse(dashboard_contents)

      title = dashboard.dig("dashboard", "title")
      uid = dashboard.dig("dashboard", "uid")

      expect(title).to be_kind_of(String)
      expect(uid).to be_kind_of(String)

      expect(title).to match(/[-A-Za-z0-9]+/)
      expect(uid).to match(/^[-a-z0-9]+$/)
    end

    it "has a null id" do
      json = JSON.parse(dashboard_contents)

      dashboard = json["dashboard"]
      expect(dashboard).not_to(be(nil), "does not include a dashboard object")

      id_exists = dashboard.key?("id")
      id = dashboard["id"]
      expect(id_exists).to(be(true), "must include an 'id' key")
      expect(id).to(be(nil), "must specify id: null")
    end
  end
end
