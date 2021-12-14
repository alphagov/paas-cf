def round_up(value, increment)
  increment * ((value + increment - 1) / increment)
end

RSpec.shared_examples "evenly distributable" do |group_name|
  it "by ensuring instance count is a multiple of AZ count" do
    expect(group_name).not_to be_nil
    ig = subject.fetch("instance_groups." + group_name)
    az_count = ig.fetch("azs").size
    instance_count = ig.fetch("instances")
    expect(instance_count % az_count).to eq(0),
      group_name + " instance count (#{instance_count}) is not divisible by AZ count (#{az_count})"
  end
end

RSpec.describe "Instance counts in different environments" do
  %w[prod prod-lon stg-lon].each do |env|
    context "for the #{env} environment" do
      subject { manifest_for_env(env) }

      let(:env_manifest) { manifest_for_env(env) }

      describe "cells" do
        it_behaves_like("evenly distributable", "diego-cell")
      end

      describe "doppler" do
        it_behaves_like("evenly distributable", "doppler")

        it "instance count should be at least half of the cell count" do
          doppler_ig = env_manifest.fetch("instance_groups.doppler")
          cell_instance_count = env_manifest.fetch("instance_groups.diego-cell").dig("instances").to_f
          doppler_instance_count = doppler_ig.dig("instances").to_f
          # Comment out check for overreaching instance count for now:
          # This check does not consider cells in isolation segments
          # doppler_az_count = doppler_ig.fetch("azs").size

          half = cell_instance_count / 2
          # half_with_headroom = round_up(half, doppler_az_count) + doppler_az_count

          expect(doppler_instance_count).to be >= half, "doppler instance count #{doppler_instance_count} is wrong. Rule of thumb is there should be at least half the count of cells in dopplers. Currently set to #{doppler_instance_count}, expecting at least #{half}."
          # expect(doppler_instance_count).to be <= half_with_headroom, "doppler instance count #{doppler_instance_count} is too high. There is no need to allow more headroom than a single set of #{doppler_az_count}. Currently set to #{doppler_instance_count}, expecting at least #{half_with_headroom}."
        end
      end

      describe "log-api" do
        it_behaves_like("evenly distributable", "log-api")

        it "instance count should be at least half of the doppler count" do
          log_api_ig = env_manifest.fetch("instance_groups.log-api")
          doppler_instance_count = env_manifest.fetch("instance_groups.doppler").dig("instances").to_f
          log_api_instances_count = log_api_ig.dig("instances").to_f
          log_api_az_count = log_api_ig.fetch("azs").size

          half = doppler_instance_count / 2
          half_with_headroom = round_up(half, log_api_az_count) + log_api_az_count

          expect(log_api_instances_count).to be >= half, "log-api instance count #{log_api_instances_count} is wrong. Rule of thumb is there should be at least half the count of dopplers in log-api. Currently set to #{log_api_instances_count}, expecting at least #{half}."
          expect(log_api_instances_count).to be <= half_with_headroom, "log-api instance count #{log_api_instances_count} is too high. There is no need to allow more headroom than a single set of three. Currently set to #{log_api_instances_count}, expecting at least #{half_with_headroom}."
        end
      end

      describe "cc-worker" do
        it_behaves_like("evenly distributable", "cc-worker")

        it "instance count should be at least half of the API instance count" do
          cc_worker_ig = env_manifest.fetch("instance_groups.cc-worker")
          api_instance_count = env_manifest.fetch("instance_groups.api").dig("instances").to_f
          cc_worker_instances_count = cc_worker_ig.dig("instances").to_f
          cc_worker_az_count = cc_worker_ig.fetch("azs").size

          half = api_instance_count / 2
          half_with_headroom = round_up(half, cc_worker_az_count) + cc_worker_az_count

          expect(cc_worker_instances_count).to be >= half, "cc-worker instance count #{cc_worker_instances_count} is wrong. Rule of thumb is there should be at least half the count of api in cc-workers. Currently set to #{cc_worker_instances_count}, expecting at least #{half}."
          expect(cc_worker_instances_count).to be <= half_with_headroom, "cc-worker instance count #{cc_worker_instances_count} is too high. There is no need to allow more headroom than a single set of #{cc_worker_az_count}. Currently set to #{cc_worker_instances_count}, expecting at least #{half_with_headroom}."
        end
      end

      describe "scheduler" do
        it "instance count should be at least half of the API instance count" do
          scheduler_ig = env_manifest.fetch("instance_groups.scheduler")
          api_instance_count = env_manifest.fetch("instance_groups.api").dig("instances").to_f
          scheduler_instances_count = scheduler_ig.dig("instances").to_f
          # Comment out check for overreaching instance count for now:
          # This check does not consider cells in isolation segments
          # scheduler_az_count = scheduler_ig.fetch("azs").size

          half = api_instance_count / 2
          # half_with_headroom = round_up(half, scheduler_az_count) + scheduler_az_count

          expect(scheduler_instances_count).to be >= half, "scheduler instance count #{scheduler_instances_count} is wrong. Rule of thumb is there should be at least half the count of api in schedulers. Currently set to #{scheduler_instances_count}, expecting at least #{half}."
          # expect(scheduler_instances_count).to be <= half_with_headroom, "log-api instance count #{scheduler_instances_count} is too high. There is no need to allow more headroom than a single set of #{scheduler_az_count}. Currently set to #{scheduler_instances_count}, expecting at least #{half_with_headroom}."
        end
      end
    end
  end
end
