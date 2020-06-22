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
      .map { |region, config| [region, config.dig("pricing_plans")] }
      .to_h
  end

  it "should be valid json" do
    billing_config_by_region.each do |region, config|
      expect { JSON.parse(config) }.not_to raise_exception,
        "#{region} is invalid JSON"
    end
  end

  describe "pricing_plans" do
    it "should be valid from the start of the month" do
      pricing_plans_by_region.each do |region, plans|
        plans.each do |plan|
          plan_name = plan.dig("name")
          valid_from = plan.dig("valid_from")

          expect(valid_from).to match(/\d{4}-\d{2}-01/),
            "#{region}/#{plan_name} is not valid from the start of the month"
        end
      end
    end
  end
end
