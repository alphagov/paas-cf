require "ipaddr"

RSpec.describe "autoscaler" do
  let(:uuid_regexp) { /^\h{8}-\h{4}-\h{4}-\h{4}-\h{12}$/i }

  let(:manifest) { manifest_with_defaults }

  describe "scalingengine" do
    subject(:scalingengine) { manifest["instance_groups.scalingengine"] }

    let(:jobs) { subject["jobs"] }

    it_behaves_like "a cf rds client"

    describe "scalingengine" do
      let(:scalingengine) { jobs.find { |j| j["name"] == "scalingengine" } }

      it "sets the client id and secret" do
        cf = scalingengine.dig("properties", "autoscaler", "cf")

        expect(cf["client_id"]).to eq("app_autoscaler")
        expect(cf["secret"]).to eq("((/test/test/uaa_clients_app_autoscaler_secret))")
      end
    end
  end

  describe "scheduler" do
    subject(:scheduler) { manifest["instance_groups.scheduler"] }

    it_behaves_like "a cf rds client"
  end

  describe "operator" do
    subject(:operator) { manifest["instance_groups.operator"] }

    let(:jobs) { subject["jobs"] }

    it_behaves_like "a cf rds client"

    describe "operator" do
      let(:operator) { jobs.find { |j| j["name"] == "operator" } }

      it "sets the client id and secret" do
        cf = operator.dig("properties", "autoscaler", "cf")

        expect(cf["client_id"]).to eq("app_autoscaler")
        expect(cf["secret"]).to eq("((/test/test/uaa_clients_app_autoscaler_secret))")
      end
    end
  end

  describe "apiserver" do
    subject(:apiserver) { manifest["instance_groups.apiserver"] }

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

  describe "eventgenerator" do
    subject(:eventgenerator) { manifest["instance_groups.eventgenerator"] }

    it_behaves_like "a cf rds client"
  end

  describe "metricsforwarder" do
    subject(:metricsforwarder) { manifest["instance_groups.metricsforwarder"] }

    it_behaves_like "a cf rds client"
  end

  describe "metricsserver" do
    subject(:metricsserver) { manifest["instance_groups.metricsserver"] }

    it_behaves_like "a cf rds client"
  end

  describe "metricsgateway" do
    subject(:metricsgateway) { manifest["instance_groups.metricsgateway"] }

    it_behaves_like "a cf rds client"
  end
end
