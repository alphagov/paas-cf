# rubocop:disable RSpec/ExpectInHook
# rubocop:disable RSpec/SubjectStub

require_relative "../set_process_log_rate_limits"

K = 1024

RSpec.describe ProcessLogRateLimitSetter do
  subject(:limit_setter) { described_class.new(organization_quota, new_limit) }

  let(:organization_quota) do
    {
      "apps" => {
        "log_rate_limit_in_bytes_per_second" => current_limit,
      },
      "relationships" => {
        "organizations" => {
          "data" => [
            { "guid" => "11111111-1111-1111-1111-111111111111" },
            { "guid" => "22222222-2222-2222-2222-222222222222" },
          ],
        },
      },
    }
  end
  let(:current_limit) { 123 * K }
  let(:new_limit) { "12K" }

  context "when the quota currently has no limit" do
    let(:current_limit) { nil }

    context "and the new limit is unlimited" do
      let(:new_limit) { nil }

      it "does nothing" do
        expect(limit_setter).not_to receive(:'`')
        limit_setter.apply!
      end
    end

    [12 * K, "12K", 12.0 * K].each do |nl|
      context "and the new limit is finite (#{nl.inspect})" do
        let(:new_limit) { nl }

        let(:processes_response_hash_111) do
          {
            "pagination" => {
              "total_pages" => 1,
            },
            "resources" => [
              {
                "guid" => "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
                "log_rate_limit_in_bytes_per_second" => 321,
              },
              {
                "guid" => "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb",
                "log_rate_limit_in_bytes_per_second" => -1,
              },
            ],
          }
        end
        let(:processes_response_json_111) { JSON.generate(processes_response_hash_111) }
        let(:processes_response_hash_222) do
          {
            "pagination" => {
              "total_pages" => 1,
            },
            "resources" => [
              {
                "guid" => "cccccccc-cccc-cccc-cccc-cccccccccccc",
                "log_rate_limit_in_bytes_per_second" => 13 * K,
              },
            ],
          }
        end
        let(:processes_response_json_222) { JSON.generate(processes_response_hash_222) }

        context "and no problems are encountered" do
          before do
            expect(limit_setter).to receive(:'`').with("cf curl -f '/v3/processes?per_page=5000&organization_guids=11111111-1111-1111-1111-111111111111'") do
              system("exit 0") # setup $?
              processes_response_json_111
            end

            expect(limit_setter).to receive(:'`').with("cf curl -f '/v3/processes?per_page=5000&organization_guids=22222222-2222-2222-2222-222222222222'") do
              system("exit 0") # setup $?
              processes_response_json_222
            end
          end

          it "updates processes with unlimited and higher log rate limits" do
            expect(limit_setter).to receive(:'`').with("cf curl -f '/v3/processes/bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb/actions/scale' -X POST -H \"Content-type: application/json\" -d '{\"log_rate_limit_in_bytes_per_second\": #{12 * K}}'") do
              system("exit 0") # setup $?
            end

            expect(limit_setter).to receive(:'`').with("cf curl -f '/v3/processes/cccccccc-cccc-cccc-cccc-cccccccccccc/actions/scale' -X POST -H \"Content-type: application/json\" -d '{\"log_rate_limit_in_bytes_per_second\": #{12 * K}}'") do
              system("exit 0") # setup $?
            end

            limit_setter.apply!
          end
        end

        context "and there is more than one process result page" do
          before do
            processes_response_hash_111["pagination"]["total_pages"] = 3

            expect(limit_setter).to receive(:'`').with("cf curl -f '/v3/processes?per_page=5000&organization_guids=11111111-1111-1111-1111-111111111111'") do
              system("exit 0") # setup $?
              processes_response_json_111
            end
          end

          it "raises an appropriate exception" do
            expect { limit_setter.apply! }.to raise_exception.with_message("org 11111111-1111-1111-1111-111111111111 has >5000 processes: implement proper paging for this script")
          end
        end
      end
    end
  end

  context "when the quota currently has a finite limit" do
    let(:current_limit) { 123 * K }

    context "and the new limit is unlimited" do
      let(:new_limit) { nil }

      it "does nothing" do
        expect(limit_setter).not_to receive(:'`')
        limit_setter.apply!
      end
    end

    context "and the new limit is greater than the current limit" do
      let(:new_limit) { "1M" }

      it "does nothing" do
        expect(limit_setter).not_to receive(:'`')
        limit_setter.apply!
      end
    end

    context "and the new limit is the same as the current limit" do
      let(:new_limit) { "123K" }

      it "does nothing" do
        expect(limit_setter).not_to receive(:'`')
        limit_setter.apply!
      end
    end

    context "and the new limit is lower than the current limit" do
      let(:new_limit) { "6K" }

      let(:processes_response_hash_111) do
        {
          "pagination" => {
            "total_pages" => 1,
          },
          "resources" => [
            {
              "guid" => "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
              "log_rate_limit_in_bytes_per_second" => 321,
            },
            {
              "guid" => "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb",
              "log_rate_limit_in_bytes_per_second" => -1,
            },
          ],
        }
      end
      let(:processes_response_json_111) { JSON.generate(processes_response_hash_111) }
      let(:processes_response_hash_222) do
        {
          "pagination" => {
            "total_pages" => 1,
          },
          "resources" => [
            {
              "guid" => "cccccccc-cccc-cccc-cccc-cccccccccccc",
              "log_rate_limit_in_bytes_per_second" => 11 * K,
            },
            {
              "guid" => "dddddddd-dddd-dddd-dddd-dddddddddddd",
              "log_rate_limit_in_bytes_per_second" => 6 * K, # equal to new_limit
            },
          ],
        }
      end
      let(:processes_response_json_222) { JSON.generate(processes_response_hash_222) }

      context "and no problems are encountered" do
        before do
          expect(limit_setter).to receive(:'`').with("cf curl -f '/v3/processes?per_page=5000&organization_guids=11111111-1111-1111-1111-111111111111'") do
            system("exit 0") # setup $?
            processes_response_json_111
          end

          expect(limit_setter).to receive(:'`').with("cf curl -f '/v3/processes?per_page=5000&organization_guids=22222222-2222-2222-2222-222222222222'") do
            system("exit 0") # setup $?
            processes_response_json_222
          end
        end

        it "updates processes with unlimited and higher log rate limits" do
          expect(limit_setter).to receive(:'`').with("cf curl -f '/v3/processes/bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb/actions/scale' -X POST -H \"Content-type: application/json\" -d '{\"log_rate_limit_in_bytes_per_second\": #{6 * K}}'") do
            system("exit 0") # setup $?
          end

          expect(limit_setter).to receive(:'`').with("cf curl -f '/v3/processes/cccccccc-cccc-cccc-cccc-cccccccccccc/actions/scale' -X POST -H \"Content-type: application/json\" -d '{\"log_rate_limit_in_bytes_per_second\": #{6 * K}}'") do
            system("exit 0") # setup $?
          end

          limit_setter.apply!
        end
      end
    end
  end
end

# rubocop:enable RSpec/SubjectStub
# rubocop:enable RSpec/ExpectInHook
