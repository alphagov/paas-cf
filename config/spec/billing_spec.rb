require "json"

BILLING_PATH = File.expand_path(File.join(__dir__, "..", "billing", "output"))
BILLING_FILES = Dir.glob(File.join(BILLING_PATH, "*.json"))

describe "billing" do
  let :billing_config_by_region do
    BILLING_FILES
      .map { |r| [File.basename(r), File.read(r)] }
      .to_h
  end

  let :pricing_plans_by_region do
    BILLING_FILES
      .map { |r| [File.basename(r), JSON.parse(File.read(r))] }
      .to_h
      .transform_values { |config| config["pricing_plans"] }
  end

  it "is valid json" do
    billing_config_by_region.each do |region, config|
      expect { JSON.parse(config) }.not_to raise_exception,
        "#{region} is invalid JSON"
    end
  end

  describe "pricing_plans" do
    it "is valid from the start of the month" do
      pricing_plans_by_region.each do |region, plans|
        plans.each do |plan|
          plan_name = plan["name"]
          valid_from = plan["valid_from"]

          expect(valid_from).to match(/\d{4}-\d{2}-01/),
            "#{region}/#{plan_name} is not valid from the start of the month"
        end
      end
    end
  end
end
