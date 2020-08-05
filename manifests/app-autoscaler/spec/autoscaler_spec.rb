require "ipaddr"

RSpec.describe "autoscaler" do
  let(:manifest) { manifest_with_defaults }

  describe "actors" do
    subject(:actors) { manifest["instance_groups.asactors"] }

    let(:jobs) { subject["jobs"] }

    it_behaves_like "a cf rds client"

    describe "scalingengine" do
      let(:scalingengine) { jobs.find { |j| j["name"] == "scalingengine" } }

      it "sets the client id and secret" do
        puts scalingengine.dig("properties", "autoscaler", "cf")

        cf = scalingengine.dig("properties", "autoscaler", "cf")

        expect(cf["client_id"]).to eq("app_autoscaler")
        expect(cf["secret"]).to eq("((/test/test/uaa_clients_app_autoscaler_secret))")
      end
    end

    describe "operator" do
      let(:operator) { jobs.find { |j| j["name"] == "operator" } }

      it "sets the client id and secret" do
        cf = operator.dig("properties", "autoscaler", "cf")

        expect(cf["client_id"]).to eq("app_autoscaler")
        expect(cf["secret"]).to eq("((/test/test/uaa_clients_app_autoscaler_secret))")
      end
    end
  end

  describe "api" do
    subject(:api) { manifest["instance_groups.asapi"] }

    let(:jobs) { subject["jobs"] }

    it_behaves_like "a cf rds client"

    describe "golangapiserver" do
      let(:apiserver) { jobs.find { |j| j["name"] == "golangapiserver" } }

      it "sets the client id and secret" do
        cf = apiserver.dig("properties", "autoscaler", "cf")

        expect(cf["client_id"]).to eq("app_autoscaler")
        expect(cf["secret"]).to eq("((/test/test/uaa_clients_app_autoscaler_secret))")
      end
    end
  end

  describe "metrics" do
    subject(:metrics) { manifest["instance_groups.asmetrics"] }

    it_behaves_like "a cf rds client"
  end

  describe "nozzle" do
    subject(:nozzle) { manifest["instance_groups.asnozzle"] }

    it_behaves_like "a cf rds client"
  end
end
