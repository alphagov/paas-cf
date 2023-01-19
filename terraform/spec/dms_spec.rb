require "json"

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
end
