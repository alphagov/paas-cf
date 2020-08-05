RSpec.describe "vars" do
  let(:manifest) { manifest_with_defaults }
  let(:vars) { manifest.fetch("variables") }

  describe "certificates" do
    let(:certs) { vars.select { |v| v["type"] == "certificate" } }

    it "uses correct alternative names" do
      certs.each do |c|
        name = c["name"]
        alt_names = c.dig("options", "alternative_names") || []

        alt_names.each do |alt_name|
          expect(alt_name).not_to match(/default/),
            "#{name} should not have default network in alt names, has #{alt_name}"
        end
      end
    end
  end
end
