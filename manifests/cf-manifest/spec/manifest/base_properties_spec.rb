RSpec.describe "base properties" do
  let(:manifest) { manifest_with_defaults }

  it "sets the top-level manifest name" do
    expect(manifest["name"]).to eq(terraform_fixture_value(:environment))
  end

  it "has global max_in_flight set to 30%" do
    expect(manifest["update"].fetch("max_in_flight")).to eq("30%")
  end

  it "has global canaries set to 1" do
    expect(manifest["update"].fetch("canaries")).to eq(1)
  end

  it "does not have meta top level key" do
    expect(manifest.fetch("meta", "not_found")).to eq "not_found"
  end

  it "does not have secrets top level key" do
    expect(manifest.fetch("secrets", "not_found")).to eq "not_found"
  end

  it "does not have terraform_outputs top level key" do
    expect(manifest.fetch("terraform_outputs", "not_found")).to eq "not_found"
  end

  describe "stemcells" do
    let(:stemcells) { manifest.fetch("stemcells") }

    it "all stemcells specify an os" do
      stemcells.each do |stemcell|
        os = stemcell["os"]
        expect(os).not_to be_nil, "stemcell #{stemcell['alias']} does not specify an os"
      end
    end

    it "default stemcell os matches cf-deployment manifest" do
      default = stemcells.find { |s| s["alias"] == "default" }
      cf_deployment_default = cf_deployment_manifest.fetch("stemcells").find { |s| s["alias"] == "default" }

      expect(default["os"]).to eq(cf_deployment_default.fetch("os"))
    end

    it "stemcell version is not older than the one in cf-deployment **iff they're the same major version**" do
      default = stemcells.find { |s| s["alias"] == "default" }
      cf_deployment_default = cf_deployment_manifest.fetch("stemcells").find { |s| s["alias"] == "default" }

      if default["version"].to_s.split(".")[0] == cf_deployment_default.fetch("version").to_s.split(".")[0]
        expect(Gem::Version.new(default["version"])).to be >= Gem::Version.new(cf_deployment_default.fetch("version")),
        "the stemcell version should not be older than in cf-deployment"
      end
    end
  end

  describe "api cloud_controller_ng" do
    subject(:cloud_controller_ng_properties) {
      manifest["instance_groups.api.jobs.cloud_controller_ng.properties"]
    }
    subject(:cc) {
      manifest["instance_groups.api.jobs.cloud_controller_ng.properties.cc"]
    }

    it "sets the system_domain from the terraform outputs" do
      expect(cloud_controller_ng_properties["system_domain"]).to eq(terraform_fixture_value(:cf_root_domain))
    end
    it "sets the app domains" do
      expect(cloud_controller_ng_properties["app_domains"]).to match_array([
        terraform_fixture_value(:cf_apps_domain),
      ])
    end

    shared_examples "a component with an AWS connection" do
      let(:fog_connection) { subject.fetch("fog_connection") }

      specify { expect(fog_connection).to include("use_iam_profile" => true) }
      specify { expect(fog_connection).to include("region" => terraform_fixture_value(:region)) }
      specify { expect(fog_connection).to include("provider" => "AWS") }
    end

    describe "buildpacks" do
      subject(:buildpacks) { cc.fetch("buildpacks") }

      it_behaves_like "a component with an AWS connection"

      it { is_expected.to include("buildpack_directory_key" => "#{terraform_fixture_value(:environment)}-cf-buildpacks") }
    end

    describe "droplets" do
      subject(:droplets) { cc.fetch("droplets") }

      it_behaves_like "a component with an AWS connection"

      it { is_expected.to include("droplet_directory_key" => "#{terraform_fixture_value(:environment)}-cf-droplets") }
    end

    describe "packages" do
      subject(:packages) { cc.fetch("packages") }

      it_behaves_like "a component with an AWS connection"

      it { is_expected.to include("app_package_directory_key" => "#{terraform_fixture_value(:environment)}-cf-packages") }
    end

    describe "resource_pool" do
      subject(:resource_pool) { cc.fetch("resource_pool") }

      it_behaves_like "a component with an AWS connection"

      it { is_expected.to include("resource_directory_key" => "#{terraform_fixture_value(:environment)}-cf-resources") }
    end
  end

  describe "scheduler cloud_controller_clock" do
    subject(:cc) {
      manifest["instance_groups.scheduler.jobs.cloud_controller_clock.properties.cc"]
    }

    describe "app_usage_events" do
      subject(:app_usage_events) { cc.fetch("app_usage_events") }

      it { is_expected.to include("cutoff_age_in_days" => 45), "We expect retention period for data to be 45 days." }
    end

    describe "service_usage_events" do
      subject(:service_usage_events) { cc.fetch("service_usage_events") }

      it { is_expected.to include("cutoff_age_in_days" => 45), "We expect retention period for data to be 45 days." }
    end
  end

  describe "uaa login" do
    subject(:login) { manifest["instance_groups.uaa.jobs.uaa.properties.login"] }

    describe "smtp" do
      subject(:smtp) { login.fetch("smtp") }

      it { is_expected.to include("host" => "SmtpHost") }
      it { is_expected.to include("user" => "SmtpAccessTokenID") }
      it { is_expected.to include("password" => "SmtpPassword") }
    end

    describe "links" do
      subject(:links) { login.fetch("links") }

      it { is_expected.to include("passwd" => "https://admin.#{terraform_fixture_value(:cf_root_domain)}/password/request-reset") }
      it { is_expected.to include("signup" => "https://www.cloud.service.gov.uk/signup") }
      it { is_expected.to include("homeRedirect" => "https://admin.#{terraform_fixture_value(:cf_root_domain)}/") }
    end
  end

  describe "uaa" do
    subject(:uaa) { manifest["instance_groups.uaa.jobs.uaa.properties.uaa"] }

    it { is_expected.to include("issuer" => "https://uaa.#{terraform_fixture_value(:cf_root_domain)}") }
    it { is_expected.to include("url" => "https://uaa.#{terraform_fixture_value(:cf_root_domain)}") }

    describe "clients" do
      subject(:clients) { uaa.fetch("clients") }

      it {
        clients.each { |_, config|
          expect(config).to have_key("override")
          expect(config["override"]).to be true
        }
      }

      describe "login" do
        subject(:client) { clients.fetch("login") }
        it {
          is_expected.to include("redirect-uri" => "https://login.#{terraform_fixture_value(:cf_root_domain)}")
        }
      end
    end
  end

  describe "diego-cell rep" do
    describe "executor" do
      subject(:executor) { manifest["instance_groups.diego-cell.jobs.rep.properties.diego.executor"] }

      it "has a memory_capacity_mb of at least 32G" do
        memory_capacity_mb = executor["memory_capacity_mb"]
        expect(memory_capacity_mb).to be_a_kind_of(Integer)
        expect(memory_capacity_mb).to be >= (32 * 1024)
      end
    end
  end

  describe "buildpacks" do
    let(:install_buildpacks_property) {
      manifest["instance_groups.api.jobs.cloud_controller_ng.properties.cc.install_buildpacks"]
    }

    it "install_buildpacks does not contain buildpacks" do
      expect(install_buildpacks_property).to be_nil.or be_empty
    end
  end

  describe "router" do
    subject(:router) { manifest["instance_groups.router.jobs.gorouter.properties.router"] }

    it "sets route_services_secret" do
      expect(router["route_services_secret"]).not_to be_empty
    end
  end
end
