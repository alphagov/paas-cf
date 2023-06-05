require "json"

RSpec.describe "grafana dashboard" do
  grafana_dashboards.each do |dashboard_name, dashboard_contents|
    context dashboard_name do
      it "ends in .json" do
        expect(dashboard_name).to match(/[.]json$/)
      end

      it "is valid json" do
        expect { JSON.parse dashboard_contents }.not_to raise_error
      end

      it "has a title and uid" do
        dashboard = JSON.parse(dashboard_contents)

        title = dashboard["title"]
        uid = dashboard["uid"]

        expect(title).to be_kind_of(String)
        expect(uid).to be_kind_of(String)

        expect(title).to match(/[-A-Za-z0-9]+/)
        expect(uid).to match(/^[-a-z0-9]+$/)
        expect(uid.length).to be <= 40
      end

      it "has a null id" do
        dashboard = JSON.parse(dashboard_contents)

        id_exists = dashboard.key?("id")
        id = dashboard["id"]
        expect(id_exists).to(be(true), "must include an 'id' key")
        expect(id).to(be(nil), "must specify id: null")
      end
    end
  end
end
