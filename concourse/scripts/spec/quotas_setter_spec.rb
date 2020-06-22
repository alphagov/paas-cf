# rubocop:disable RSpec/SubjectStub

require_relative "../set_quotas_from_manifest"

RSpec.describe QuotasSetter do
  subject(:quota_setter) { described_class.new(manifest) }

  let(:quota_definitions) { {} }
  let(:manifest) do
  {
    "instance_groups" => [
      "name" => "api",
      "jobs" => {
        "cloud_controller_ng" => {
          "properties" => {
            "cc" => {
              "quota_definitions" => quota_definitions,
            },
          },
        },
      },
    ],
  }
end

  describe "creating/updating quotas" do
    before do
      allow(quota_setter).to receive(:system).with("cf", /^(create|update)-quota$/, any_args) do
        system("exit 0")
      end

      quota_definitions["default"] = {
        "memory_limit" => 2048,
        "total_services" => 10,
        "total_routes" => 1000,
        "non_basic_services_allowed" => false,
      }
      quota_definitions["large"] = {
        "memory_limit" => 10_240,
        "total_services" => 100,
        "total_routes" => 10_000,
        "non_basic_services_allowed" => true,
      }
    end

    context "with no extant quotas" do
      before do
        allow(quota_setter).to receive(:`).with("cf quotas") do
          system("exit 0") # setup $?
          <<-EOT
Getting quotas as admin...
OK

name                                    total memory   instance memory   routes   service instances   paid plans   app instances   route ports
          EOT
        end
      end

      it "creates the quotas" do
        expect_cf_quota_create("default", "-m", "2048M", "-s", "10", "-r", "1000", "--disallow-paid-service-plans")
        expect_cf_quota_create("large", "-m", "10240M", "-s", "100", "-r", "10000", "--allow-paid-service-plans")

        quota_setter.apply!
      end
    end

    context "when some quotas exist" do
      before do
        allow(quota_setter).to receive(:`).with("cf quotas") do
          system("exit 0") # setup $?
          <<-EOT
Getting quotas as admin...
OK

name                                    total memory   instance memory   routes   service instances   paid plans   app instances   route ports
default                                 2G             unlimited         1000     10                  disallowed   unlimited       0
          EOT
        end
      end

      it "updates an existing quota" do
        expect_cf_quota_update("default", "-m", "2048M", "-s", "10", "-r", "1000", "--disallow-paid-service-plans")
        quota_setter.apply!
      end

      it "creates a quota that doesn't already exist" do
        expect_cf_quota_create("large", "-m", "10240M", "-s", "100", "-r", "10000", "--allow-paid-service-plans")
        quota_setter.apply!
      end
    end
  end

  def expect_cf_quota_write(name, action, *args)
    expect(quota_setter).to receive(:system).with("cf", action, name, *args) do
      system("exit 0") # setup $?
    end
  end

  def expect_cf_quota_create(name, *args)
    expect_cf_quota_write(name, "create-quota", *args)
  end

  def expect_cf_quota_update(name, *args)
    expect_cf_quota_write(name, "update-quota", *args)
  end
end
# rubocop:enable RSpec/SubjectStub
