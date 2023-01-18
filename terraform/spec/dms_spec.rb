require "json"

describe "dms" do
  Dir.glob("../*.dms.json") do |f|
    describe f do
      it "names must contain only valid characters" do
        cfg = JSON.read_file(f, aliases: true)
        names = cfg.map { |e| e["name"] }

        expect(names).to all(match(/^[\-A-Za-z0-9._\/]+$/))
      end
    end
  end
end
