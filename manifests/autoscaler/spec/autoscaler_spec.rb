require "ipaddr"

RSpec.describe "autoscaler" do
  let(:manifest) { manifest_with_defaults }

  describe "actors" do
    let(:actors) { manifest["instance_groups.asactors"] }
    let(:jobs) { actors["jobs"] }

    describe "scalingengine" do
      let(:scalingengine) { jobs.find { |j| j["name"] == "scalingengine" } }

      it "sets the client id and secret" do
        puts scalingengine.dig("properties", "autoscaler", "cf")

        cf = scalingengine.dig("properties", "autoscaler", "cf")

        expect(cf["client_id"]).to eq("autoscaler")
        expect(cf["secret"]).to eq("((/test/test/uaa_clients_autoscaler_secret))")
      end
    end

    describe "operator" do
      let(:operator) { jobs.find { |j| j["name"] == "operator" } }

      it "sets the client id and secret" do
        cf = operator.dig("properties", "autoscaler", "cf")

        expect(cf["client_id"]).to eq("autoscaler")
        expect(cf["secret"]).to eq("((/test/test/uaa_clients_autoscaler_secret))")
      end
    end
  end

  describe "api" do
    let(:api) { manifest["instance_groups.asapi"] }
    let(:jobs) { api["jobs"] }

    describe "golangapiserver" do
      let(:apiserver) { jobs.find { |j| j["name"] == "golangapiserver" } }

      it "sets the client id and secret" do
        cf = apiserver.dig("properties", "autoscaler", "cf")

        expect(cf["client_id"]).to eq("autoscaler")
        expect(cf["secret"]).to eq("((/test/test/uaa_clients_autoscaler_secret))")
      end
    end
  end
end
