require "ipaddr"

RSpec.describe "autoscaler" do
  let(:uuid_regexp) { /^\h{8}-\h{4}-\h{4}-\h{4}-\h{12}$/i }

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

      describe "catalog" do
        let(:catalog) do
          apiserver.dig(
            "properties", "autoscaler", "apiserver",
            "broker", "server", "catalog"
          )
        end

        let(:services) { catalog["services"] }

        it "has a real guid for each service" do
          services.each do |service|
            expect(service["id"]).to match(uuid_regexp),
              "#{service['name']} should have a guid id instead of #{service['id']}"
          end
        end

        it "has a real guid for each plan" do
          services.each do |service|
            service["plans"].each do |plan|
              expect(plan["id"]).to match(uuid_regexp),
                "#{plan['name']} should have a guid id instead of #{plan['id']}"
            end
          end
        end
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
