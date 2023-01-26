require "json"
require "ipaddr"
require "yaml"
require "open3"

describe "dms" do
  Dir.glob("../*.dms.json") do |f|
    describe f do
      it "names must contain only valid characters" do
        cfg = JSON.read_file(f, aliases: true)
        names = cfg.map { |e| e["name"] }

        expect(names).to all(match(/^[\-A-Za-z0-9._\/]+$/))
      end

      it "must have a storage size between 5 and 6144" do
        cfg = JSON.read_file(f, aliases: true)
        allocated_storages = cfg.map { |e| e["instance"]["allocated_storage"].to_int }
        expect(allocated_storages).to all(be_between(5, 6144))
      end

      it "must have a source secret beginning with dms-secrets" do
        cfg = JSON.read_file(f, aliases: true)
        source_secrets = cfg.map { |e| e["source_secret_name"] }

        expect(source_secrets).to all(match(/^dms-secrets.*$/))
      end

      it "must have a target secret beginning with dms-secrets" do
        cfg = JSON.read_file(f, aliases: true)
        target_secrets = cfg.map { |e| e["target_secret_name"] }

        expect(target_secrets).to all(match(/^dms-secrets.*$/))
      end
    end
  end

  describe "CIDR verification" do
    let(:variables_file) { File.read("dms/variables.tf") }
    let(:yaml_file) { YAML.load_file("../manifests/cf-manifest/operations.d/770-secret-manager-endpoint.yml") }
    let(:tf_json) { JSON.parse(Open3.capture2("hcl2json dms/variables.tf")[0]) }
    let(:variables) { tf_json["variable"]["aws_vpc_endpoint_cidrs_per_zone"] }
    let(:cidrs) { variables[0]["default"].values }
    let(:ranges) { cidrs.map { |cidr| IPAddr.new(cidr).to_range.to_s.gsub("..", "-") } }
    let(:yaml_ranges) do
      yaml_file.find { |i| i["path"] == "/instance_groups/name=api/jobs/name=cloud_controller_ng/properties/cc/security_group_definitions/-" }["value"]["rules"].map { |r| r["destination"] }
    end

    it "verifies that the CIDRs in variables.tf match the ranges in 770-secret-manager-endpoint.yml" do
      expect(ranges).to match_array(yaml_ranges)
    end
  end
end
