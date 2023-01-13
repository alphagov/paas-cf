require "ipaddr"

def is_egress_restricted(segment)
  coredns = segment["jobs"].find { |j| j["name"] == "coredns" }
  !coredns.nil?
end

RSpec.describe "isolation_segments" do
  describe "default" do
    let(:manifest) { manifest_with_defaults }

    let(:bosh_dns_cell_aliases) do
      manifest
        .fetch("addons.bosh-dns-aliases.jobs.bosh-dns-aliases.properties.aliases")
        .find { |a| a["domain"] == "_.cell.service.cf.internal" }
        .fetch("targets")
    end

    describe "egress-restricted-1" do
      let(:instance_group) { manifest.fetch("instance_groups.diego-cell-iso-seg-egress-restricted-1") }

      it "is added to the manifest" do
        expect { instance_group }.not_to raise_error
      end

      it "correctly gets a single instance" do
        expect(instance_group["instances"]).to eq(0)
      end

      it "correctly sets the vm_type when the size is changed" do
        expect(instance_group["vm_type"]).to eq("small_cell")

        expect(
          instance_group["jobs"]
            .find { |j| j["name"] == "rep" }
            .dig("properties", "diego", "executor", "memory_capacity_mb"),
        ).to eq(27_197)
      end

      it "has the correct placement tag" do
        expect(
          instance_group["jobs"]
            .find { |j| j["name"] == "rep" }
            .dig("properties", "diego", "rep", "placement_tags"),
        ).to eq(%w[egress-restricted-1])
      end

      it "has an override for vxlan-policy-agent provider" do
        expect(
          instance_group["jobs"]
            .find { |j| j["name"] == "vxlan-policy-agent" }["provides"],
        ).to eq("vpa" => { "as" => "vpa-egress-restricted-1" })
      end

      it "has an override for garden provider" do
        expect(
          instance_group["jobs"]
            .find { |j| j["name"] == "garden" }["provides"],
        ).to eq("iptables" => { "as" => "iptables-egress-restricted-1" })
      end

      it "has an override for silk-cni consumer" do
        expect(
          instance_group["jobs"]
            .find { |j| j["name"] == "silk-cni" }["consumes"],
        ).to eq("vpa" => { "from" => "vpa-egress-restricted-1" })
      end

      it "has an override for silk-daemon consumer" do
        expect(
          instance_group["jobs"]
            .find { |j| j["name"] == "silk-daemon" }["consumes"],
        ).to eq("iptables" => { "from" => "iptables-egress-restricted-1" }, "vpa" => { "from" => "vpa-egress-restricted-1" })
      end

      it "is added to bosh-dns-aliases for cells" do
        expect(bosh_dns_cell_aliases).to include(
          "query" => "_",
          "instance_group" => "diego-cell-iso-seg-egress-restricted-1",
          "network" => "cell",
          "deployment" => "unit-test",
          "domain" => "bosh",
        )
      end

      it "includes the coredns job" do
        coredns_job = instance_group["jobs"]
          .find { |j| j["name"] == "coredns" }

        expected_corefile = <<~COREFILE
        (common) {
          health :8054
          ready
          log
          prometheus :9153
          bind 169.254.0.3
        }

        buildpacks.cloudfoundry.org {
          import common
          forward . 169.254.0.2:53
        }

        apps.internal {
          import common
          forward . 169.254.0.2:53
        }
        COREFILE

        expect(coredns_job).not_to be_nil
        expect(coredns_job["release"]).to eq("observability")
        expect(coredns_job.dig("properties", "corefile")).to match(
          expected_corefile,
        )
      end

      it "sets silk-cni dns_servers to be the local coredns resolver" do
        expect(
          instance_group["jobs"]
            .find { |j| j["name"] == "silk-cni" }
            .dig("properties", "dns_servers"),
        ).to eq(["169.254.0.3"])
      end

      it "sets silk-cni deny_networks to allow the vpc" do
        vpc_examples = %w[
          10.0.0.1
          10.10.0.1
          10.10.0.1
          10.10.0.255
          10.255.0.1
          10.255.0.255
        ]

        denied_ranges = instance_group["jobs"]
          .find { |j| j["name"] == "silk-cni" }
          .dig("properties", "deny_networks", "running")
          .map(&IPAddr.method(:new))

        denied_ranges.each do |denied_range|
          vpc_examples.each do |a_vpc_address|
            expect(denied_range.include?(a_vpc_address)).to(
              eq(false),
              "silk-cni deny_networks #{denied_range} denies #{a_vpc_address}",
            )
          end
        end
      end

      it "sets silk-cni deny_networks to deny any except the vpc" do
        example_addresses = (1..255)
          .reject { |n| n == 10 }
          .map { |first_group|
            last_three_groups = Array.new(3).fill { rand(1..255) }
            [first_group].concat(last_three_groups).map(&:to_s).join(".")
          }
          .concat(%w[9.255.255.255 11.0.0.0])

        denied_ranges = instance_group["jobs"]
          .find { |j| j["name"] == "silk-cni" }
          .dig("properties", "deny_networks", "running")
          .map(&IPAddr.method(:new))

        allowed_ips = example_addresses.reject { |a| denied_ranges.any? { |r| r.include? a } }

        expect(allowed_ips).to eq([])
      end

      it "does not set silk-cni deny_networks for staging or always" do
        %w[always staging].each do |workload|
          denied_ranges = instance_group["jobs"]
            .find { |j| j["name"] == "silk-cni" }
            .dig("properties", "deny_networks", workload)

          expect(denied_ranges).to be_nil
        end
      end
    end

    describe "not-egress-restricted-1" do
      let(:instance_group) { manifest.fetch("instance_groups.diego-cell-iso-seg-not-egress-restricted-1") }

      it "is added to the manifest" do
        expect { instance_group }.not_to raise_error
      end

      it "correctly gets a zero instances" do
        expect(instance_group["instances"]).to eq(0)
      end

      it "does not override the default vm_type if it is not set" do
        expect(instance_group["vm_type"]).to eq("cell")
      end

      it "has the correct placement tag" do
        expect(
          instance_group["jobs"]
            .find { |j| j["name"] == "rep" }
            .dig("properties", "diego", "rep", "placement_tags"),
        ).to eq(%w[not-egress-restricted-1])
      end

      it "has an override for vxlan-policy-agent provider" do
        expect(
          instance_group["jobs"]
            .find { |j| j["name"] == "vxlan-policy-agent" }["provides"],
        ).to eq("vpa" => { "as" => "vpa-not-egress-restricted-1" })
      end

      it "has an override for garden provider" do
        expect(
          instance_group["jobs"]
            .find { |j| j["name"] == "garden" }["provides"],
        ).to eq("iptables" => { "as" => "iptables-not-egress-restricted-1" })
      end

      it "does not include the coredns job" do
        expect(
          instance_group["jobs"]
            .find { |j| j["name"] == "coredns" },
        ).to be_nil
      end

      it "does not override the default bosh-dns silk-cni dns_servers" do
        expect(
          instance_group["jobs"]
            .find { |j| j["name"] == "silk-cni" }
            .dig("properties", "dns_servers"),
        ).to eq(["169.254.0.2"])
      end

      it "has an override for silk-cni consumer" do
        expect(
          instance_group["jobs"]
            .find { |j| j["name"] == "silk-cni" }["consumes"],
        ).to eq("vpa" => { "from" => "vpa-not-egress-restricted-1" })
      end

      it "has an override for silk-daemon consumer" do
        expect(
          instance_group["jobs"]
            .find { |j| j["name"] == "silk-daemon" }["consumes"],
        ).to eq("iptables" => { "from" => "iptables-not-egress-restricted-1" }, "vpa" => { "from" => "vpa-not-egress-restricted-1" })
      end

      it "is added to bosh-dns-aliases for cells" do
        expect(bosh_dns_cell_aliases).to include(
          "query" => "_",
          "instance_group" => "diego-cell-iso-seg-not-egress-restricted-1",
          "network" => "cell",
          "deployment" => "unit-test",
          "domain" => "bosh",
        )
      end
    end
  end

  describe "specific environments" do
    # while we have no tenants using egress restricted isolation segments
    # we test that they exist but are scaled to zero

    let(:instance_groups) { manifest.fetch("instance_groups") }
    let(:segs) { instance_groups.select { |i| i["name"] =~ /diego-cell-iso/ } }

    describe "stg-lon" do
      let(:manifest) { manifest_for_env("stg-lon") }

      it "contains an empty egress restricted isolation segment" do
        expect(segs.count).to eq(1)
        seg = segs.first
        expect(seg["instances"]).to eq(0)
        expect(seg["jobs"].find { |j| j["name"] == "coredns" }).not_to be_nil
      end
    end

    describe "prod" do
      let(:manifest) { manifest_for_env("prod") }

      it "contains an empty egress restricted isolation segment" do
        expect(segs.count).to be >= 1
        seg = segs.select { |s| s["name"] == "diego-cell-iso-seg-egress-restricted-1" }.first
        expect(seg).not_to be_nil
        expect(seg["instances"]).to eq(0)
        expect(seg["jobs"].find { |j| j["name"] == "coredns" }).not_to be_nil
      end

      it "contains an egress-unrestricted isolation segment for GOV.UK Notify production" do
        expect(segs.count).to be >= 1
        seg = segs.select { |s| s["name"] == "diego-cell-iso-seg-govuk-notify-production" }.first
        expect(seg).not_to be_nil
        expect(seg["instances"]).to be >= 1
        expect(seg["jobs"].find { |j| j["name"] == "coredns" }).to be_nil
      end
    end

    describe "prod-lon" do
      let(:manifest) { manifest_for_env("prod-lon") }

      it "contains an non-empty egress restricted isolation segment" do
        expect(segs.count).to eq(1)
        seg = segs.first
        expect(seg["instances"]).to eq(2)
        expect(seg["jobs"].find { |j| j["name"] == "coredns" }).not_to be_nil
      end
    end
  end
end
