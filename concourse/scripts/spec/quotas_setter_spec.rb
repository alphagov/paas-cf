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
  let(:log_rate_limit_setter) do
    class_double("ProcessLogRateLimitSetter").as_stubbed_const(transfer_nested_constants: true)
  end

  describe "creating/updating quotas" do
    before do
      allow(quota_setter).to receive(:system).with("cf", /^(create|update)-quota$/, any_args) do
        system("exit 0") # setup $?
      end

      quota_definitions["default"] = {
        "memory_limit" => 2048,
        "total_services" => 10,
        "total_routes" => 1000,
        "non_basic_services_allowed" => false,
        "log_rate_limit" => "21",
      }
      quota_definitions["medium"] = {
        "memory_limit" => 4096,
        "total_services" => 20,
        "total_routes" => 2_000,
        "non_basic_services_allowed" => true,
        "log_rate_limit" => "12K",
      }
      quota_definitions["large"] = {
        "memory_limit" => 10_240,
        "total_services" => 100,
        "total_routes" => 10_000,
        "non_basic_services_allowed" => true,
        "log_rate_limit" => "123K",
      }
    end

    context "with no extant quotas" do
      before do
        allow(quota_setter).to receive(:'`').with("cf curl -f '/v3/organization_quotas'") do
          system("exit 0") # setup $?
          <<-EOT
{"resources": []}
          EOT
        end
      end

      it "creates the quotas" do
        expect_cf_quota_create("default", "-m", "2048M", "-s", "10", "-r", "1000", "--disallow-paid-service-plans", "-l", "21")
        expect_cf_quota_create("large", "-m", "10240M", "-s", "100", "-r", "10000", "--allow-paid-service-plans", "-l", "123K")

        quota_setter.apply!
      end
    end

    context "when some quotas exist" do
      let(:response_hash) do
        {
          "resources" => [
            {
              "name" => "default",
              "apps" => {
                "log_rate_limit_in_bytes_per_second" => 1234,
              },
              "relationships" => {
                "organizations" => {
                  "data" => [
                    { "guid" => "11111111-1111-1111-1111-111111111111" },
                    { "guid" => "22222222-2222-2222-2222-222222222222" },
                  ],
                },
              },
            },
            {
              "name" => "unrelated",
              "relationships" => {
                "organizations" => {
                  "data" => [
                    { "guid" => "dddddddd-dddd-dddd-dddd-dddddddddddd" },
                  ],
                },
              },
            },
            {
              "name" => "medium",
              "apps" => {
                "log_rate_limit_in_bytes_per_second" => 1299,
              },
              "relationships" => {
                "organizations" => {
                  "data" => [
                    { "guid" => "33333333-3333-3333-3333-333333333333" },
                  ],
                },
              },
            },
          ],
        }
      end
      let(:response_json) { JSON.generate(response_hash) }

      before do
        allow(quota_setter).to receive(:'`').with("cf curl -f '/v3/organization_quotas'") do
          system("exit 0") # setup $?
          response_json
        end
      end

      it "updates existing quotas and creates non-existing quotas" do
        expect(log_rate_limit_setter).to receive(:new).with(
          response_hash["resources"][0],
          "21",
        ) do
          lrs = instance_double("ProcessLogRateLimitSetter")
          expect(lrs).to receive(:apply!)
          lrs
        end

        expect(log_rate_limit_setter).to receive(:new).with(
          response_hash["resources"][2],
          "12K",
        ) do
          lrs = instance_double("ProcessLogRateLimitSetter")
          expect(lrs).to receive(:apply!)
          lrs
        end

        expect_cf_quota_update("default", "-m", "2048M", "-s", "10", "-r", "1000", "--disallow-paid-service-plans", "-l", "21")
        expect_cf_quota_update("medium", "-m", "4096M", "-s", "20", "-r", "2000", "--allow-paid-service-plans", "-l", "12K")

        expect_cf_quota_create("large", "-m", "10240M", "-s", "100", "-r", "10000", "--allow-paid-service-plans", "-l", "123K")

        quota_setter.apply!
      end

      context "and some are missing log_rate_limit" do
        before do
          quota_definitions["medium"].delete("log_rate_limit")
        end

        it "calls ProcessLogRateLimitSetter with nil and omits -l from quota update" do
          expect(log_rate_limit_setter).to receive(:new).with(
            response_hash["resources"][0],
            "21",
          ) do
            lrs = instance_double("ProcessLogRateLimitSetter")
            expect(lrs).to receive(:apply!)
            lrs
          end

          expect(log_rate_limit_setter).to receive(:new).with(
            response_hash["resources"][2],
            nil,
          ) do
            lrs = instance_double("ProcessLogRateLimitSetter")
            expect(lrs).to receive(:apply!)
            lrs
          end

          expect_cf_quota_update("default", "-m", "2048M", "-s", "10", "-r", "1000", "--disallow-paid-service-plans", "-l", "21")
          expect_cf_quota_update("medium", "-m", "4096M", "-s", "20", "-r", "2000", "--allow-paid-service-plans")

          expect_cf_quota_create("large", "-m", "10240M", "-s", "100", "-r", "10000", "--allow-paid-service-plans", "-l", "123K")

          quota_setter.apply!
        end
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
