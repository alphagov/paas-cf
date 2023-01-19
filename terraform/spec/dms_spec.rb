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
    end
  end
end
