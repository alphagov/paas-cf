
RSpec.describe "loggregator_trafficcontroller jobs" do
  LOGGREGATOR_JOBS = %w(
    loggregator_trafficcontroller_z1
    loggregator_trafficcontroller_z2
  )

  let(:jobs) { manifest_with_defaults.fetch("jobs") }

  describe "common job properties" do
    LOGGREGATOR_JOBS.each do |job_name|
      context "job #{job_name}" do
        subject(:job) { jobs.find {|j| j["name"] == job_name } }

        describe "route registrar" do
          let(:routes) { job.fetch("properties").fetch("route_registrar").fetch("routes") }

          it "registers the necessary routes" do
            expect(routes.map {|r| r["name"]}).to match_array(%w[doppler loggregator])
          end

          it "registers the correct doppler uris" do
            doppler_uris = routes.find {|r| r["name"] == "doppler"}.fetch("uris")
            expect(doppler_uris).to match_array([
              "doppler.#{terraform_fixture(:cf_root_domain)}",
            ])
          end

          it "registers the correct loggregator uris" do
            doppler_uris = routes.find {|r| r["name"] == "loggregator"}.fetch("uris")
            expect(doppler_uris).to match_array([
              "loggregator.#{terraform_fixture(:cf_root_domain)}",
            ])
          end
        end
      end
    end
  end
end
