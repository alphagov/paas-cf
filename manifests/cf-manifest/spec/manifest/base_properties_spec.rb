
RSpec.describe "base properties" do
  let(:manifest) { manifest_with_defaults }
  let(:properties) { manifest.fetch("properties") }

  it "sets the top-level manifest name" do
    expect(manifest["name"]).to eq(terraform_fixture(:environment))
  end

  it "has global max_in_flight set to 1" do
    expect(manifest["update"].fetch("max_in_flight")).to eq(1)
  end

  it "sets the system_domain from the terraform outputs" do
    expect(properties["system_domain"]).to eq(terraform_fixture(:cf_root_domain))
  end

  it "sets the app domains" do
    expect(properties["app_domains"]).to match_array([
      terraform_fixture(:cf_apps_domain),
    ])
  end

  describe "cloud controller" do
    subject(:cc) { properties.fetch("cc") }

    it { is_expected.to include("srv_api_uri" => "https://api.#{terraform_fixture(:cf_root_domain)}") }

    shared_examples "a component with an AWS connection" do
      let(:fog_connection) { subject.fetch("fog_connection") }

      specify { expect(fog_connection).to include("use_iam_profile" => true) }
      specify { expect(fog_connection).to include("region" => terraform_fixture(:region)) }
      specify { expect(fog_connection).to include("provider" => "AWS") }
    end

    describe "buildpacks" do
      subject(:buildpacks) { cc.fetch("buildpacks") }

      it_behaves_like "a component with an AWS connection"

      it { is_expected.to include("buildpack_directory_key" => "#{terraform_fixture(:environment)}-cf-buildpacks") }
    end

    describe "droplets" do
      subject(:droplets) { cc.fetch("droplets") }

      it_behaves_like "a component with an AWS connection"

      it { is_expected.to include("droplet_directory_key" => "#{terraform_fixture(:environment)}-cf-droplets") }
    end

    describe "packages" do
      subject(:packages) { cc.fetch("packages") }

      it_behaves_like "a component with an AWS connection"

      it { is_expected.to include("app_package_directory_key" => "#{terraform_fixture(:environment)}-cf-packages") }
    end

    describe "resource_pool" do
      subject(:resource_pool) { cc.fetch("resource_pool") }

      it_behaves_like "a component with an AWS connection"

      it { is_expected.to include("resource_directory_key" => "#{terraform_fixture(:environment)}-cf-resources") }
    end

    describe "app_events" do
      subject(:app_events) { cc.fetch("app_events") }

      it { is_expected.to include("cutoff_age_in_days" => 31), "We expect retention period for data to be 31 days." }
    end

    describe "app_usage_events" do
      subject(:app_usage_events) { cc.fetch("app_usage_events") }

      it { is_expected.to include("cutoff_age_in_days" => 45), "We expect retention period for data to be 45 days." }
    end

    describe "service_usage_events" do
      subject(:service_usage_events) { cc.fetch("service_usage_events") }

      it { is_expected.to include("cutoff_age_in_days" => 45), "We expect retention period for data to be 45 days." }
    end

    describe "audit_events" do
      subject(:audit_events) { cc.fetch("audit_events") }

      it { is_expected.to include("cutoff_age_in_days" => 31), "We expect retention period for data to be 31 days." }
    end
  end

  describe "login" do
    subject(:login) { properties.fetch("login") }

    describe "smtp" do
      subject(:smtp) { login.fetch("smtp") }

      it { is_expected.to include("host" => "SmtpHost") }
      it { is_expected.to include("user" => "SmtpAccessTokenID") }
      it { is_expected.to include("password" => "SmtpPassword") }
    end

    describe "links" do
      subject(:links) { login.fetch("links") }

      it { is_expected.to include("passwd" => "https://login.#{terraform_fixture(:cf_root_domain)}/forgot_password") }
      it { is_expected.to include("signup" => "https://www.cloud.service.gov.uk/signup") }
      it { is_expected.to include("homeRedirect" => "https://www.cloud.service.gov.uk/next-steps?account-updated") }
    end
  end

  describe "uaa" do
    subject(:uaa) { properties.fetch("uaa") }

    it { is_expected.to include("issuer" => "https://uaa.#{terraform_fixture(:cf_root_domain)}") }
    it { is_expected.to include("url" => "https://uaa.#{terraform_fixture(:cf_root_domain)}") }


    describe "clients" do
      subject(:clients) { uaa.fetch("clients") }

      it {
        expect(clients.keys).to contain_exactly(
          "login",
          "cf",
          "notifications",
          "doppler",
          "cloud_controller_username_lookup",
          "cc_routing",
          "gorouter",
          "tcp_emitter",
          "tcp_router",
          "ssh-proxy",
          "graphite-nozzle",
          "paas-admin",
          "paas-metrics",
          "datadog-nozzle",
          "cc-service-dashboards",
          "cc_service_key_client",
          "cdn_broker",
          "paas-billing",
          "user_invitation",
        )
      }

      it {
        clients.each { |_, config|
          expect(config).to have_key("override")
          expect(config["override"]).to be true
        }
      }

      describe "login" do
        subject(:client) { clients.fetch("login") }
        it {
          is_expected.to include("redirect-uri" => "https://login.#{terraform_fixture(:cf_root_domain)}")
        }
      end

      def comma_tokenize(str)
        str.split(",").map(&:strip)
      end

      describe "datadog-nozzle" do
        subject(:client) { clients.fetch("datadog-nozzle") }
        it {
          expect(comma_tokenize(client["authorized-grant-types"])).to contain_exactly(
            "authorization_code",
            "client_credentials",
            "refresh_token",
          )
        }
        it {
          expect(comma_tokenize(client["scope"])).to contain_exactly(
            "openid",
            "oauth.approvals",
            "doppler.firehose",
          )
        }
        it {
          expect(comma_tokenize(client["authorities"])).to contain_exactly(
            "oauth.login",
            "doppler.firehose",
          )
        }
      end
    end
  end

  describe "diego" do
    subject(:diego) { properties.fetch("diego") }

    describe "executor" do
      subject(:executor) { diego.fetch("executor") }

      it "should have a memory_capacity_mb of at least 30G" do
        memory_capacity_mb = executor['memory_capacity_mb']
        expect(memory_capacity_mb).to be_a_kind_of(Integer)
        expect(memory_capacity_mb).to be >= (30 * 1024)
      end
    end
  end

  describe "buildpacks" do
    let(:api_instance_group) { manifest_with_defaults.fetch("instance_groups").find { |j| j.fetch("name") == "api" } }
    let(:api_job_names) { api_instance_group.fetch("jobs").map { |t| t.fetch("name") } }

    let(:install_buildpacks_property) { properties.fetch("cc").fetch("install_buildpacks") }

    it "install_buildpacks reference packages that exist" do
      install_buildpacks_property.each do |pack|
        expect(api_job_names).to include(pack.fetch("package")),
          "install_buildpacks entry #{pack.fetch('name')} references non-existent package #{pack.fetch('package')}"
      end
    end
  end

  describe "router" do
    subject(:router) { properties.fetch("router") }

    it "sets route_services_secret" do
      expect(router["route_services_secret"]).not_to be_empty
    end
  end
end
